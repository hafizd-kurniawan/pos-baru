package repository

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/jmoiron/sqlx"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
)

type SalesRepository interface {
	Create(transaction *models.SalesTransaction) (*models.SalesTransaction, error)
	GetByID(id int) (*models.SalesTransaction, error)
	List(offset, limit int, status, dateFrom, dateTo string, customerID *int) ([]models.SalesTransaction, int64, error)
	Update(transaction *models.SalesTransaction) (*models.SalesTransaction, error)
	Delete(id int) error
	GetByInvoiceNumber(invoiceNumber string) (*models.SalesTransaction, error)
}

type salesRepository struct {
	db *sqlx.DB
}

func NewSalesRepository(db *sqlx.DB) SalesRepository {
	return &salesRepository{db: db}
}

func (r *salesRepository) Create(transaction *models.SalesTransaction) (*models.SalesTransaction, error) {
	query := `
		INSERT INTO sales_transactions (
			invoice_number, transaction_date, customer_id, vehicle_id, 
			hpp_price, selling_price, profit, payment_method, payment_status,
			down_payment, remaining_payment, notes, processed_by, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
		) RETURNING id`

	now := time.Now()
	err := r.db.QueryRow(
		query,
		transaction.InvoiceNumber,
		transaction.TransactionDate,
		transaction.CustomerID,
		transaction.VehicleID,
		transaction.HPPPrice,
		transaction.SellingPrice,
		transaction.Profit,
		transaction.PaymentMethod,
		transaction.PaymentStatus,
		transaction.DownPayment,
		transaction.RemainingPayment,
		transaction.Notes,
		transaction.ProcessedBy,
		now,
		now,
	).Scan(&transaction.ID)

	if err != nil {
		return nil, fmt.Errorf("failed to create sales transaction: %v", err)
	}

	transaction.CreatedAt = now
	transaction.UpdatedAt = now

	return transaction, nil
}

func (r *salesRepository) GetByID(id int) (*models.SalesTransaction, error) {
	query := `
		SELECT 
			st.id, st.invoice_number, st.transaction_date, st.customer_id, st.vehicle_id,
			st.hpp_price, st.selling_price, st.profit, st.payment_method, st.payment_status,
			st.down_payment, st.remaining_payment, st.notes, st.processed_by, st.created_at, st.updated_at,
			c.id as customer_id, c.name as customer_name, c.phone as customer_phone, 
			c.email as customer_email, c.address as customer_address,
			v.id as vehicle_id, v.brand, v.model, v.year, v.license_plate, v.color, 
			v.purchase_price, v.selling_price as vehicle_selling_price, v.status as vehicle_status,
			u.id as user_id, u.name as user_name, u.email as user_email
		FROM sales_transactions st
		LEFT JOIN customers c ON st.customer_id = c.id
		LEFT JOIN vehicles v ON st.vehicle_id = v.id
		LEFT JOIN users u ON st.processed_by = u.id
		WHERE st.id = $1`

	var transaction models.SalesTransaction
	var customer models.Customer
	var vehicle models.Vehicle
	var processor models.User

	err := r.db.QueryRow(query, id).Scan(
		&transaction.ID, &transaction.InvoiceNumber, &transaction.TransactionDate,
		&transaction.CustomerID, &transaction.VehicleID, &transaction.HPPPrice,
		&transaction.SellingPrice, &transaction.Profit, &transaction.PaymentMethod,
		&transaction.PaymentStatus, &transaction.DownPayment, &transaction.RemainingPayment,
		&transaction.Notes, &transaction.ProcessedBy, &transaction.CreatedAt, &transaction.UpdatedAt,
		&customer.ID, &customer.Name, &customer.Phone, &customer.Email, &customer.Address,
		&vehicle.ID, &vehicle.Brand, &vehicle.Model, &vehicle.Year, &vehicle.LicensePlate,
		&vehicle.Color, &vehicle.PurchasePrice, &vehicle.SellingPrice, &vehicle.Status,
		&processor.ID, &processor.FullName, &processor.Email,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("sales transaction not found")
		}
		return nil, fmt.Errorf("failed to get sales transaction: %v", err)
	}

	transaction.Customer = &customer
	transaction.Vehicle = &vehicle
	transaction.Processor = &processor

	return &transaction, nil
}

func (r *salesRepository) List(offset, limit int, status, dateFrom, dateTo string, customerID *int) ([]models.SalesTransaction, int64, error) {
	conditions := []string{}
	args := []interface{}{}
	argIndex := 1

	// Build WHERE conditions
	if status != "" {
		conditions = append(conditions, fmt.Sprintf("st.payment_status = $%d", argIndex))
		args = append(args, status)
		argIndex++
	}

	if dateFrom != "" {
		conditions = append(conditions, fmt.Sprintf("st.transaction_date >= $%d", argIndex))
		args = append(args, dateFrom)
		argIndex++
	}

	if dateTo != "" {
		conditions = append(conditions, fmt.Sprintf("st.transaction_date <= $%d", argIndex))
		args = append(args, dateTo)
		argIndex++
	}

	if customerID != nil {
		conditions = append(conditions, fmt.Sprintf("st.customer_id = $%d", argIndex))
		args = append(args, *customerID)
		argIndex++
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	// Count total records
	countQuery := fmt.Sprintf(`
		SELECT COUNT(*) 
		FROM sales_transactions st 
		%s`, whereClause)

	var total int64
	err := r.db.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count sales transactions: %v", err)
	}

	// Get paginated results
	query := fmt.Sprintf(`
		SELECT 
			st.id, st.invoice_number, st.transaction_date, st.customer_id, st.vehicle_id,
			st.hpp_price, st.selling_price, st.profit, st.payment_method, st.payment_status,
			st.down_payment, st.remaining_payment, st.notes, st.processed_by, st.created_at, st.updated_at,
			c.name as customer_name, c.phone as customer_phone,
			v.brand, v.model, v.year, v.license_plate,
			u.name as processor_name
		FROM sales_transactions st
		LEFT JOIN customers c ON st.customer_id = c.id
		LEFT JOIN vehicles v ON st.vehicle_id = v.id
		LEFT JOIN users u ON st.processed_by = u.id
		%s
		ORDER BY st.created_at DESC
		LIMIT $%d OFFSET $%d`,
		whereClause, argIndex, argIndex+1)

	args = append(args, limit, offset)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list sales transactions: %v", err)
	}
	defer rows.Close()

	var transactions []models.SalesTransaction
	for rows.Next() {
		var transaction models.SalesTransaction
		var customerName, customerPhone sql.NullString
		var vehicleBrand, vehicleModel, vehicleLicensePlate sql.NullString
		var vehicleYear sql.NullInt32
		var processorName sql.NullString

		err := rows.Scan(
			&transaction.ID, &transaction.InvoiceNumber, &transaction.TransactionDate,
			&transaction.CustomerID, &transaction.VehicleID, &transaction.HPPPrice,
			&transaction.SellingPrice, &transaction.Profit, &transaction.PaymentMethod,
			&transaction.PaymentStatus, &transaction.DownPayment, &transaction.RemainingPayment,
			&transaction.Notes, &transaction.ProcessedBy, &transaction.CreatedAt, &transaction.UpdatedAt,
			&customerName, &customerPhone,
			&vehicleBrand, &vehicleModel, &vehicleYear, &vehicleLicensePlate,
			&processorName,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan sales transaction: %v", err)
		}

		// Add related data if available
		if customerName.Valid {
			phone := customerPhone.String
			transaction.Customer = &models.Customer{
				ID:    transaction.CustomerID,
				Name:  customerName.String,
				Phone: &phone,
			}
		}

		if vehicleBrand.Valid {
			licensePlate := vehicleLicensePlate.String
			transaction.Vehicle = &models.Vehicle{
				ID: transaction.VehicleID,
				Brand: &models.VehicleBrand{
					Name: vehicleBrand.String,
				},
				Model:        vehicleModel.String,
				Year:         int(vehicleYear.Int32),
				LicensePlate: &licensePlate,
			}
		}

		if processorName.Valid {
			transaction.Processor = &models.User{
				ID:       transaction.ProcessedBy,
				FullName: processorName.String,
			}
		}

		transactions = append(transactions, transaction)
	}

	return transactions, total, nil
}

func (r *salesRepository) Update(transaction *models.SalesTransaction) (*models.SalesTransaction, error) {
	query := `
		UPDATE sales_transactions 
		SET selling_price = $1, profit = $2, payment_method = $3, payment_status = $4,
			down_payment = $5, remaining_payment = $6, notes = $7, updated_at = $8
		WHERE id = $9`

	now := time.Now()
	_, err := r.db.Exec(
		query,
		transaction.SellingPrice,
		transaction.Profit,
		transaction.PaymentMethod,
		transaction.PaymentStatus,
		transaction.DownPayment,
		transaction.RemainingPayment,
		transaction.Notes,
		now,
		transaction.ID,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to update sales transaction: %v", err)
	}

	transaction.UpdatedAt = now

	return transaction, nil
}

func (r *salesRepository) Delete(id int) error {
	query := `DELETE FROM sales_transactions WHERE id = $1`

	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete sales transaction: %v", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %v", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("sales transaction not found")
	}

	return nil
}

func (r *salesRepository) GetByInvoiceNumber(invoiceNumber string) (*models.SalesTransaction, error) {
	query := `
		SELECT 
			st.id, st.invoice_number, st.transaction_date, st.customer_id, st.vehicle_id,
			st.hpp_price, st.selling_price, st.profit, st.payment_method, st.payment_status,
			st.down_payment, st.remaining_payment, st.notes, st.processed_by, st.created_at, st.updated_at
		FROM sales_transactions st
		WHERE st.invoice_number = $1`

	var transaction models.SalesTransaction
	err := r.db.QueryRow(query, invoiceNumber).Scan(
		&transaction.ID, &transaction.InvoiceNumber, &transaction.TransactionDate,
		&transaction.CustomerID, &transaction.VehicleID, &transaction.HPPPrice,
		&transaction.SellingPrice, &transaction.Profit, &transaction.PaymentMethod,
		&transaction.PaymentStatus, &transaction.DownPayment, &transaction.RemainingPayment,
		&transaction.Notes, &transaction.ProcessedBy, &transaction.CreatedAt, &transaction.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("sales transaction not found")
		}
		return nil, fmt.Errorf("failed to get sales transaction: %v", err)
	}

	return &transaction, nil
}
