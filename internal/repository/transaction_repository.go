package repository

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/pkg/database"
)

type TransactionRepository interface {
	CreatePurchaseTransaction(req *models.PurchaseTransactionCreateRequest, processedBy int) (*models.PurchaseTransaction, error)
	CreateSalesTransaction(req *models.SalesTransactionCreateRequest, processedBy int) (*models.SalesTransaction, error)
	GetPurchaseTransactionByID(id int) (*models.PurchaseTransaction, error)
	GetSalesTransactionByID(id int) (*models.SalesTransaction, error)
	GetPurchaseTransactionByInvoice(invoiceNumber string) (*models.PurchaseTransaction, error)
	GetSalesTransactionByInvoice(invoiceNumber string) (*models.SalesTransaction, error)
	ListPurchaseTransactions(page, limit int, dateFrom, dateTo *time.Time) ([]models.PurchaseTransaction, int64, error)
	ListSalesTransactions(page, limit int, dateFrom, dateTo *time.Time) ([]models.SalesTransaction, int64, error)
	UpdatePurchasePaymentStatus(id int, req *models.PaymentUpdateRequest) error
	UpdateSalesPaymentStatus(id int, req *models.PaymentUpdateRequest) error
	GetDailyTransactionSummary(date time.Time) (float64, float64, float64, error) // purchase, sales, profit
}

type transactionRepository struct {
	db *database.Database
}

func NewTransactionRepository(db *database.Database) TransactionRepository {
	return &transactionRepository{db: db}
}

func (r *transactionRepository) CreatePurchaseTransaction(req *models.PurchaseTransactionCreateRequest, processedBy int) (*models.PurchaseTransaction, error) {
	// Generate invoice number
	invoiceNumber := fmt.Sprintf("PUR%d%03d", time.Now().Unix(), req.VehicleID)

	query := `
		INSERT INTO purchase_transactions (
			invoice_number, transaction_date, source_type, source_id, vehicle_id, 
			purchase_price, payment_method, payment_status, notes, processed_by
		)
		VALUES ($1, CURRENT_DATE, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING id, invoice_number, transaction_date, source_type, source_id, vehicle_id,
				  purchase_price, payment_method, payment_status, notes, processed_by, created_at, updated_at`

	var transaction models.PurchaseTransaction
	err := r.db.Get(&transaction, query,
		invoiceNumber, req.SourceType, req.SourceID, req.VehicleID, req.PurchasePrice,
		req.PaymentMethod, req.PaymentStatus, req.Notes, processedBy)
	if err != nil {
		return nil, fmt.Errorf("failed to create purchase transaction: %w", err)
	}

	return &transaction, nil
}

func (r *transactionRepository) CreateSalesTransaction(req *models.SalesTransactionCreateRequest, processedBy int) (*models.SalesTransaction, error) {
	// First get vehicle to calculate HPP and profit
	var vehicle models.Vehicle
	vehicleQuery := `SELECT purchase_price, repair_cost, hpp_price FROM vehicles WHERE id = $1`
	err := r.db.Get(&vehicle, vehicleQuery, req.VehicleID)
	if err != nil {
		return nil, fmt.Errorf("failed to get vehicle for transaction: %w", err)
	}

	hppPrice := float64(0)
	if vehicle.HPPPrice != nil {
		hppPrice = *vehicle.HPPPrice
	}
	profit := req.SellingPrice - hppPrice
	remainingPayment := req.SellingPrice - req.DownPayment

	// Generate invoice number
	invoiceNumber := fmt.Sprintf("SAL%d%03d", time.Now().Unix(), req.VehicleID)

	query := `
		INSERT INTO sales_transactions (
			invoice_number, transaction_date, customer_id, vehicle_id, hpp_price,
			selling_price, profit, payment_method, payment_status, down_payment,
			remaining_payment, notes, processed_by
		)
		VALUES ($1, CURRENT_DATE, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		RETURNING id, invoice_number, transaction_date, customer_id, vehicle_id, hpp_price,
				  selling_price, profit, payment_method, payment_status, down_payment,
				  remaining_payment, notes, processed_by, created_at, updated_at`

	var transaction models.SalesTransaction
	err = r.db.Get(&transaction, query,
		invoiceNumber, req.CustomerID, req.VehicleID, hppPrice, req.SellingPrice, profit,
		req.PaymentMethod, req.PaymentStatus, req.DownPayment, remainingPayment,
		req.Notes, processedBy)
	if err != nil {
		return nil, fmt.Errorf("failed to create sales transaction: %w", err)
	}

	return &transaction, nil
}

func (r *transactionRepository) GetPurchaseTransactionByID(id int) (*models.PurchaseTransaction, error) {
	query := `
		SELECT 
			pt.id, pt.invoice_number, pt.transaction_date, pt.source_type, pt.source_id,
			pt.vehicle_id, pt.purchase_price, pt.payment_method, pt.payment_status,
			pt.notes, pt.processed_by, pt.created_at, pt.updated_at,
			v.id as "vehicle.id", v.code as "vehicle.code", v.model as "vehicle.model", v.year as "vehicle.year"
		FROM purchase_transactions pt
		JOIN vehicles v ON pt.vehicle_id = v.id
		WHERE pt.id = $1`

	var transaction models.PurchaseTransaction
	err := r.db.Get(&transaction, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("purchase transaction not found")
		}
		return nil, fmt.Errorf("failed to get purchase transaction: %w", err)
	}

	return &transaction, nil
}

func (r *transactionRepository) GetSalesTransactionByID(id int) (*models.SalesTransaction, error) {
	query := `
		SELECT 
			st.id, st.invoice_number, st.transaction_date, st.customer_id, st.vehicle_id,
			st.hpp_price, st.selling_price, st.profit, st.payment_method, st.payment_status,
			st.down_payment, st.remaining_payment, st.notes, st.processed_by, st.created_at, st.updated_at,
			v.id as "vehicle.id", v.code as "vehicle.code", v.model as "vehicle.model", v.year as "vehicle.year",
			c.id as "customer.id", c.name as "customer.name", c.phone as "customer.phone"
		FROM sales_transactions st
		JOIN vehicles v ON st.vehicle_id = v.id
		JOIN customers c ON st.customer_id = c.id
		WHERE st.id = $1`

	var transaction models.SalesTransaction
	err := r.db.Get(&transaction, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("sales transaction not found")
		}
		return nil, fmt.Errorf("failed to get sales transaction: %w", err)
	}

	return &transaction, nil
}

func (r *transactionRepository) GetPurchaseTransactionByInvoice(invoiceNumber string) (*models.PurchaseTransaction, error) {
	query := `
		SELECT 
			pt.id, pt.invoice_number, pt.transaction_date, pt.source_type, pt.source_id,
			pt.vehicle_id, pt.purchase_price, pt.payment_method, pt.payment_status,
			pt.notes, pt.processed_by, pt.created_at, pt.updated_at
		FROM purchase_transactions pt
		WHERE pt.invoice_number = $1`

	var transaction models.PurchaseTransaction
	err := r.db.Get(&transaction, query, invoiceNumber)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("purchase transaction not found")
		}
		return nil, fmt.Errorf("failed to get purchase transaction: %w", err)
	}

	return &transaction, nil
}

func (r *transactionRepository) GetSalesTransactionByInvoice(invoiceNumber string) (*models.SalesTransaction, error) {
	query := `
		SELECT 
			st.id, st.invoice_number, st.transaction_date, st.customer_id, st.vehicle_id,
			st.hpp_price, st.selling_price, st.profit, st.payment_method, st.payment_status,
			st.down_payment, st.remaining_payment, st.notes, st.processed_by, st.created_at, st.updated_at
		FROM sales_transactions st
		WHERE st.invoice_number = $1`

	var transaction models.SalesTransaction
	err := r.db.Get(&transaction, query, invoiceNumber)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("sales transaction not found")
		}
		return nil, fmt.Errorf("failed to get sales transaction: %w", err)
	}

	return &transaction, nil
}

func (r *transactionRepository) ListPurchaseTransactions(page, limit int, dateFrom, dateTo *time.Time) ([]models.PurchaseTransaction, int64, error) {
	offset := (page - 1) * limit

	// Build WHERE clause for date filtering
	var whereClause string
	var args []interface{}
	var countArgs []interface{}

	if dateFrom != nil && dateTo != nil {
		whereClause = "WHERE pt.transaction_date >= $1 AND pt.transaction_date <= $2"
		args = []interface{}{*dateFrom, *dateTo, limit, offset}
		countArgs = []interface{}{*dateFrom, *dateTo}
	} else if dateFrom != nil {
		whereClause = "WHERE pt.transaction_date >= $1"
		args = []interface{}{*dateFrom, limit, offset}
		countArgs = []interface{}{*dateFrom}
	} else if dateTo != nil {
		whereClause = "WHERE pt.transaction_date <= $1"
		args = []interface{}{*dateTo, limit, offset}
		countArgs = []interface{}{*dateTo}
	} else {
		whereClause = ""
		args = []interface{}{limit, offset}
		countArgs = []interface{}{}
	}

	// Get total count
	var total int64
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM purchase_transactions pt %s", whereClause)
	err := r.db.Get(&total, countQuery, countArgs...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count purchase transactions: %w", err)
	}

	// Get transactions with pagination
	var query string
	if len(countArgs) == 2 {
		query = fmt.Sprintf(`
			SELECT 
				pt.id, pt.invoice_number, pt.transaction_date, pt.source_type, pt.source_id,
				pt.vehicle_id, pt.purchase_price, pt.payment_method, pt.payment_status,
				pt.notes, pt.processed_by, pt.created_at, pt.updated_at
			FROM purchase_transactions pt
			%s
			ORDER BY pt.created_at DESC
			LIMIT $3 OFFSET $4`, whereClause)
	} else if len(countArgs) == 1 {
		query = fmt.Sprintf(`
			SELECT 
				pt.id, pt.invoice_number, pt.transaction_date, pt.source_type, pt.source_id,
				pt.vehicle_id, pt.purchase_price, pt.payment_method, pt.payment_status,
				pt.notes, pt.processed_by, pt.created_at, pt.updated_at
			FROM purchase_transactions pt
			%s
			ORDER BY pt.created_at DESC
			LIMIT $2 OFFSET $3`, whereClause)
	} else {
		query = `
			SELECT 
				pt.id, pt.invoice_number, pt.transaction_date, pt.source_type, pt.source_id,
				pt.vehicle_id, pt.purchase_price, pt.payment_method, pt.payment_status,
				pt.notes, pt.processed_by, pt.created_at, pt.updated_at
			FROM purchase_transactions pt
			ORDER BY pt.created_at DESC
			LIMIT $1 OFFSET $2`
	}

	var transactions []models.PurchaseTransaction
	err = r.db.Select(&transactions, query, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list purchase transactions: %w", err)
	}

	return transactions, total, nil
}

func (r *transactionRepository) ListSalesTransactions(page, limit int, dateFrom, dateTo *time.Time) ([]models.SalesTransaction, int64, error) {
	offset := (page - 1) * limit

	// Build WHERE clause for date filtering
	var whereClause string
	var args []interface{}
	var countArgs []interface{}

	if dateFrom != nil && dateTo != nil {
		whereClause = "WHERE st.transaction_date >= $1 AND st.transaction_date <= $2"
		args = []interface{}{*dateFrom, *dateTo, limit, offset}
		countArgs = []interface{}{*dateFrom, *dateTo}
	} else if dateFrom != nil {
		whereClause = "WHERE st.transaction_date >= $1"
		args = []interface{}{*dateFrom, limit, offset}
		countArgs = []interface{}{*dateFrom}
	} else if dateTo != nil {
		whereClause = "WHERE st.transaction_date <= $1"
		args = []interface{}{*dateTo, limit, offset}
		countArgs = []interface{}{*dateTo}
	} else {
		whereClause = ""
		args = []interface{}{limit, offset}
		countArgs = []interface{}{}
	}

	// Get total count
	var total int64
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM sales_transactions st %s", whereClause)
	err := r.db.Get(&total, countQuery, countArgs...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count sales transactions: %w", err)
	}

	// Get transactions with pagination
	var query string
	if len(countArgs) == 2 {
		query = fmt.Sprintf(`
			SELECT 
				st.id, st.invoice_number, st.transaction_date, st.customer_id, st.vehicle_id,
				st.hpp_price, st.selling_price, st.profit, st.payment_method, st.payment_status,
				st.down_payment, st.remaining_payment, st.notes, st.processed_by, st.created_at, st.updated_at
			FROM sales_transactions st
			%s
			ORDER BY st.created_at DESC
			LIMIT $3 OFFSET $4`, whereClause)
	} else if len(countArgs) == 1 {
		query = fmt.Sprintf(`
			SELECT 
				st.id, st.invoice_number, st.transaction_date, st.customer_id, st.vehicle_id,
				st.hpp_price, st.selling_price, st.profit, st.payment_method, st.payment_status,
				st.down_payment, st.remaining_payment, st.notes, st.processed_by, st.created_at, st.updated_at
			FROM sales_transactions st
			%s
			ORDER BY st.created_at DESC
			LIMIT $2 OFFSET $3`, whereClause)
	} else {
		query = `
			SELECT 
				st.id, st.invoice_number, st.transaction_date, st.customer_id, st.vehicle_id,
				st.hpp_price, st.selling_price, st.profit, st.payment_method, st.payment_status,
				st.down_payment, st.remaining_payment, st.notes, st.processed_by, st.created_at, st.updated_at
			FROM sales_transactions st
			ORDER BY st.created_at DESC
			LIMIT $1 OFFSET $2`
	}

	var transactions []models.SalesTransaction
	err = r.db.Select(&transactions, query, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list sales transactions: %w", err)
	}

	return transactions, total, nil
}

func (r *transactionRepository) UpdatePurchasePaymentStatus(id int, req *models.PaymentUpdateRequest) error {
	query := `
		UPDATE purchase_transactions 
		SET payment_status = $1, notes = COALESCE($2, notes), updated_at = CURRENT_TIMESTAMP
		WHERE id = $3`

	result, err := r.db.Exec(query, req.PaymentStatus, req.Notes, id)
	if err != nil {
		return fmt.Errorf("failed to update purchase payment status: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("purchase transaction not found")
	}

	return nil
}

func (r *transactionRepository) UpdateSalesPaymentStatus(id int, req *models.PaymentUpdateRequest) error {
	// Build dynamic update query
	setParts := []string{"payment_status = $1", "updated_at = CURRENT_TIMESTAMP"}
	args := []interface{}{req.PaymentStatus}
	argCounter := 2

	if req.DownPayment != nil {
		setParts = append(setParts, fmt.Sprintf("down_payment = $%d", argCounter))
		args = append(args, *req.DownPayment)
		argCounter++
	}

	if req.RemainingPayment != nil {
		setParts = append(setParts, fmt.Sprintf("remaining_payment = $%d", argCounter))
		args = append(args, *req.RemainingPayment)
		argCounter++
	}

	if req.Notes != nil {
		setParts = append(setParts, fmt.Sprintf("notes = $%d", argCounter))
		args = append(args, *req.Notes)
		argCounter++
	}

	// Add WHERE clause parameter
	args = append(args, id)

	query := fmt.Sprintf(`
		UPDATE sales_transactions 
		SET %s
		WHERE id = $%d`,
		strings.Join(setParts, ", "), argCounter)

	result, err := r.db.Exec(query, args...)
	if err != nil {
		return fmt.Errorf("failed to update sales payment status: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("sales transaction not found")
	}

	return nil
}

func (r *transactionRepository) GetDailyTransactionSummary(date time.Time) (float64, float64, float64, error) {
	var purchaseTotal, salesTotal, profitTotal float64

	// Get total purchases for the day
	purchaseQuery := `
		SELECT COALESCE(SUM(purchase_price), 0) 
		FROM purchase_transactions 
		WHERE transaction_date = $1`

	err := r.db.Get(&purchaseTotal, purchaseQuery, date)
	if err != nil {
		return 0, 0, 0, fmt.Errorf("failed to get daily purchase total: %w", err)
	}

	// Get total sales and profit for the day
	salesQuery := `
		SELECT COALESCE(SUM(selling_price), 0), COALESCE(SUM(profit), 0)
		FROM sales_transactions 
		WHERE transaction_date = $1`

	err = r.db.QueryRow(salesQuery, date).Scan(&salesTotal, &profitTotal)
	if err != nil {
		return 0, 0, 0, fmt.Errorf("failed to get daily sales total: %w", err)
	}

	return purchaseTotal, salesTotal, profitTotal, nil
}
