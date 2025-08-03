package repository

import (
	"fmt"
	"time"

	"github.com/jmoiron/sqlx"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
)

type DashboardRepository interface {
	GetDashboardMetrics(date time.Time) (*models.DashboardMetric, error)
	GetRecentTransactions(limit int) ([]interface{}, error)
	GetPendingRepairs(limit int) ([]models.RepairOrder, error)
	GetLowStockItems(limit int) ([]models.SparePart, error)
	GetAvailableVehicles(limit int) ([]models.Vehicle, error)
	GetTodayTransactions(date time.Time) ([]interface{}, error)
	GetPendingPayments(limit int) ([]interface{}, error)
	GetAssignedRepairs(mechanicID int) ([]models.RepairOrder, error)
	GetCompletedRepairsToday(mechanicID int, date time.Time) ([]models.RepairOrder, error)
	GetRequiredPartsForRepairs(mechanicID int) ([]models.SparePart, error)
	GetMonthlyStats(month, year int) (*models.MonthlyClosing, error)
	GetTopPerformance() (map[string]interface{}, error)
	CreateDailyClosing(userID int, req *models.DailyClosingCreateRequest) (*models.DailyClosing, error)
	CreateMonthlyClosing(userID int, req *models.MonthlyClosingCreateRequest) (*models.MonthlyClosing, error)
	UpdateDashboardMetrics(date time.Time) error
}

type dashboardRepository struct {
	db *sqlx.DB
}

func NewDashboardRepository(db *sqlx.DB) DashboardRepository {
	return &dashboardRepository{db: db}
}

func (r *dashboardRepository) GetDashboardMetrics(date time.Time) (*models.DashboardMetric, error) {
	dateStr := date.Format("2006-01-02")

	// First try to get existing metrics for the date
	metric := &models.DashboardMetric{}
	query := "SELECT * FROM dashboard_metrics WHERE metric_date::date = $1"
	err := r.db.Get(metric, query, dateStr)

	if err != nil {
		// If no existing metrics, calculate real-time
		return r.calculateRealTimeMetrics(date)
	}

	return metric, nil
}

func (r *dashboardRepository) calculateRealTimeMetrics(date time.Time) (*models.DashboardMetric, error) {
	dateStr := date.Format("2006-01-02")

	metric := &models.DashboardMetric{
		MetricDate: date,
		UpdatedAt:  time.Now(),
	}

	// Count vehicles by status
	err := r.db.Get(&metric.VehiclesAvailable,
		"SELECT COUNT(*) FROM vehicles WHERE status = 'available'")
	if err != nil {
		return nil, fmt.Errorf("failed to count available vehicles: %w", err)
	}

	err = r.db.Get(&metric.VehiclesInRepair,
		"SELECT COUNT(*) FROM vehicles WHERE status = 'in_repair'")
	if err != nil {
		return nil, fmt.Errorf("failed to count vehicles in repair: %w", err)
	}

	// Count vehicles sold today
	err = r.db.Get(&metric.VehiclesSoldToday,
		"SELECT COUNT(*) FROM sales_transactions WHERE transaction_date::date = $1", dateStr)
	if err != nil {
		return nil, fmt.Errorf("failed to count vehicles sold today: %w", err)
	}

	// Calculate revenue and profit today
	err = r.db.Get(&metric.RevenueToday,
		"SELECT COALESCE(SUM(selling_price), 0) FROM sales_transactions WHERE transaction_date::date = $1", dateStr)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate revenue today: %w", err)
	}

	err = r.db.Get(&metric.ProfitToday,
		"SELECT COALESCE(SUM(profit), 0) FROM sales_transactions WHERE transaction_date::date = $1", dateStr)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate profit today: %w", err)
	}

	// Count pending repairs
	err = r.db.Get(&metric.PendingRepairs,
		"SELECT COUNT(*) FROM repair_orders WHERE status = 'pending'")
	if err != nil {
		return nil, fmt.Errorf("failed to count pending repairs: %w", err)
	}

	// Count low stock items
	err = r.db.Get(&metric.LowStockItems,
		"SELECT COUNT(*) FROM spare_parts WHERE stock_quantity <= minimum_stock")
	if err != nil {
		return nil, fmt.Errorf("failed to count low stock items: %w", err)
	}

	return metric, nil
}

func (r *dashboardRepository) GetRecentTransactions(limit int) ([]interface{}, error) {
	transactions := []interface{}{}

	// Get recent sales transactions
	salesQuery := `
		SELECT 'sales' as type, id, invoice_number, selling_price as amount, 
		       transaction_date, payment_status, 
		       (SELECT name FROM customers WHERE id = sales_transactions.customer_id) as customer_name
		FROM sales_transactions 
		ORDER BY transaction_date DESC 
		LIMIT $1`

	var sales []map[string]interface{}
	rows, err := r.db.Query(salesQuery, limit/2)
	if err != nil {
		return nil, fmt.Errorf("failed to get recent sales: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var t map[string]interface{} = make(map[string]interface{})
		var transactionType, invoiceNumber, paymentStatus, customerName string
		var id int
		var amount float64
		var transactionDate time.Time

		err := rows.Scan(&transactionType, &id, &invoiceNumber, &amount,
			&transactionDate, &paymentStatus, &customerName)
		if err != nil {
			return nil, fmt.Errorf("failed to scan sales transaction: %w", err)
		}

		t["type"] = transactionType
		t["id"] = id
		t["invoice_number"] = invoiceNumber
		t["amount"] = amount
		t["transaction_date"] = transactionDate
		t["payment_status"] = paymentStatus
		t["customer_name"] = customerName

		sales = append(sales, t)
	}

	// Get recent purchase transactions
	purchaseQuery := `
		SELECT 'purchase' as type, id, invoice_number, purchase_price as amount, 
		       transaction_date, payment_status,
		       (SELECT name FROM suppliers WHERE id = purchase_transactions.source_id AND purchase_transactions.source_type = 'supplier') as supplier_name
		FROM purchase_transactions 
		ORDER BY transaction_date DESC 
		LIMIT $1`

	var purchases []map[string]interface{}
	rows, err = r.db.Query(purchaseQuery, limit/2)
	if err != nil {
		return nil, fmt.Errorf("failed to get recent purchases: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var t map[string]interface{} = make(map[string]interface{})
		var transactionType, invoiceNumber, paymentStatus, supplierName string
		var id int
		var amount float64
		var transactionDate time.Time

		err := rows.Scan(&transactionType, &id, &invoiceNumber, &amount,
			&transactionDate, &paymentStatus, &supplierName)
		if err != nil {
			return nil, fmt.Errorf("failed to scan purchase transaction: %w", err)
		}

		t["type"] = transactionType
		t["id"] = id
		t["invoice_number"] = invoiceNumber
		t["amount"] = amount
		t["transaction_date"] = transactionDate
		t["payment_status"] = paymentStatus
		t["supplier_name"] = supplierName

		purchases = append(purchases, t)
	}

	// Combine and return
	for _, s := range sales {
		transactions = append(transactions, s)
	}
	for _, p := range purchases {
		transactions = append(transactions, p)
	}

	return transactions, nil
}

func (r *dashboardRepository) GetPendingRepairs(limit int) ([]models.RepairOrder, error) {
	repairs := []models.RepairOrder{}
	query := `
		SELECT ro.*, vb.name as brand, vt.name as type_name, v.license_plate,
		       u.full_name as mechanic_name
		FROM repair_orders ro
		JOIN vehicles v ON ro.vehicle_id = v.id
		LEFT JOIN vehicle_brands vb ON v.brand_id = vb.id
		LEFT JOIN vehicle_types vt ON vb.type_id = vt.id
		LEFT JOIN users u ON ro.mechanic_id = u.id
		WHERE ro.status IN ('pending', 'in_progress')
		ORDER BY ro.created_at ASC
		LIMIT $1`

	err := r.db.Select(&repairs, query, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get pending repairs: %w", err)
	}

	return repairs, nil
}

func (r *dashboardRepository) GetLowStockItems(limit int) ([]models.SparePart, error) {
	spareParts := []models.SparePart{}
	query := `
		SELECT * FROM spare_parts 
		WHERE stock_quantity <= minimum_stock
		ORDER BY (stock_quantity::float / minimum_stock::float) ASC
		LIMIT $1`

	err := r.db.Select(&spareParts, query, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get low stock items: %w", err)
	}

	return spareParts, nil
}

func (r *dashboardRepository) GetAvailableVehicles(limit int) ([]models.Vehicle, error) {
	vehicles := []models.Vehicle{}
	query := `
		SELECT * FROM vehicles 
		WHERE status = 'available'
		ORDER BY created_at DESC
		LIMIT $1`

	err := r.db.Select(&vehicles, query, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get available vehicles: %w", err)
	}

	return vehicles, nil
}

func (r *dashboardRepository) GetTodayTransactions(date time.Time) ([]interface{}, error) {
	dateStr := date.Format("2006-01-02")
	return r.getTransactionsByDate(dateStr)
}

func (r *dashboardRepository) getTransactionsByDate(dateStr string) ([]interface{}, error) {
	transactions := []interface{}{}

	// Get sales transactions for the date
	salesQuery := `
		SELECT 'sales' as type, id, invoice_number, selling_price as amount, 
		       transaction_date, payment_status,
		       (SELECT name FROM customers WHERE id = sales_transactions.customer_id) as customer_name
		FROM sales_transactions 
		WHERE transaction_date::date = $1
		ORDER BY transaction_date DESC`

	rows, err := r.db.Query(salesQuery, dateStr)
	if err != nil {
		return nil, fmt.Errorf("failed to get sales transactions: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var t map[string]interface{} = make(map[string]interface{})
		var transactionType, invoiceNumber, paymentStatus, customerName string
		var id int
		var amount float64
		var transactionDate time.Time

		err := rows.Scan(&transactionType, &id, &invoiceNumber, &amount,
			&transactionDate, &paymentStatus, &customerName)
		if err != nil {
			return nil, fmt.Errorf("failed to scan sales transaction: %w", err)
		}

		t["type"] = transactionType
		t["id"] = id
		t["invoice_number"] = invoiceNumber
		t["amount"] = amount
		t["transaction_date"] = transactionDate
		t["payment_status"] = paymentStatus
		t["customer_name"] = customerName

		transactions = append(transactions, t)
	}

	// Get purchase transactions for the date
	purchaseQuery := `
		SELECT 'purchase' as type, id, invoice_number, purchase_price as amount, 
		       transaction_date, payment_status,
		       (SELECT name FROM suppliers WHERE id = purchase_transactions.source_id AND purchase_transactions.source_type = 'supplier') as supplier_name
		FROM purchase_transactions 
		WHERE transaction_date::date = $1
		ORDER BY transaction_date DESC`

	rows, err = r.db.Query(purchaseQuery, dateStr)
	if err != nil {
		return nil, fmt.Errorf("failed to get purchase transactions: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var t map[string]interface{} = make(map[string]interface{})
		var transactionType, invoiceNumber, paymentStatus, supplierName string
		var id int
		var amount float64
		var transactionDate time.Time

		err := rows.Scan(&transactionType, &id, &invoiceNumber, &amount,
			&transactionDate, &paymentStatus, &supplierName)
		if err != nil {
			return nil, fmt.Errorf("failed to scan purchase transaction: %w", err)
		}

		t["type"] = transactionType
		t["id"] = id
		t["invoice_number"] = invoiceNumber
		t["amount"] = amount
		t["transaction_date"] = transactionDate
		t["payment_status"] = paymentStatus
		t["supplier_name"] = supplierName

		transactions = append(transactions, t)
	}

	return transactions, nil
}

func (r *dashboardRepository) GetPendingPayments(limit int) ([]interface{}, error) {
	transactions := []interface{}{}

	// Get pending sales payments
	salesQuery := `
		SELECT 'sales' as type, id, invoice_number, selling_price as amount,
		       down_payment as paid_amount, (selling_price - down_payment) as remaining,
		       transaction_date, 
		       (SELECT name FROM customers WHERE id = sales_transactions.customer_id) as customer_name
		FROM sales_transactions 
		WHERE payment_status IN ('pending', 'partial')
		ORDER BY transaction_date ASC
		LIMIT $1`

	rows, err := r.db.Query(salesQuery, limit/2)
	if err != nil {
		return nil, fmt.Errorf("failed to get pending sales payments: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var t map[string]interface{} = make(map[string]interface{})
		var transactionType, invoiceNumber, customerName string
		var id int
		var amount, paidAmount, remaining float64
		var transactionDate time.Time

		err := rows.Scan(&transactionType, &id, &invoiceNumber, &amount,
			&paidAmount, &remaining, &transactionDate, &customerName)
		if err != nil {
			return nil, fmt.Errorf("failed to scan pending sales payment: %w", err)
		}

		t["type"] = transactionType
		t["id"] = id
		t["invoice_number"] = invoiceNumber
		t["amount"] = amount
		t["paid_amount"] = paidAmount
		t["remaining"] = remaining
		t["transaction_date"] = transactionDate
		t["customer_name"] = customerName

		transactions = append(transactions, t)
	}

	// Get pending purchase payments
	purchaseQuery := `
		SELECT 'purchase' as type, id, invoice_number, purchase_price as amount,
		       purchase_price as paid_amount, 0 as remaining,
		       transaction_date,
		       (SELECT name FROM suppliers WHERE id = purchase_transactions.source_id AND purchase_transactions.source_type = 'supplier') as supplier_name
		FROM purchase_transactions 
		WHERE payment_status IN ('pending', 'partial')
		ORDER BY transaction_date ASC
		LIMIT $1`

	rows, err = r.db.Query(purchaseQuery, limit/2)
	if err != nil {
		return nil, fmt.Errorf("failed to get pending purchase payments: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var t map[string]interface{} = make(map[string]interface{})
		var transactionType, invoiceNumber, supplierName string
		var id int
		var amount, paidAmount, remaining float64
		var transactionDate time.Time

		err := rows.Scan(&transactionType, &id, &invoiceNumber, &amount,
			&paidAmount, &remaining, &transactionDate, &supplierName)
		if err != nil {
			return nil, fmt.Errorf("failed to scan pending purchase payment: %w", err)
		}

		t["type"] = transactionType
		t["id"] = id
		t["invoice_number"] = invoiceNumber
		t["amount"] = amount
		t["paid_amount"] = paidAmount
		t["remaining"] = remaining
		t["transaction_date"] = transactionDate
		t["supplier_name"] = supplierName

		transactions = append(transactions, t)
	}

	return transactions, nil
}

func (r *dashboardRepository) GetAssignedRepairs(mechanicID int) ([]models.RepairOrder, error) {
	repairs := []models.RepairOrder{}
	query := `
		SELECT ro.*, vb.name as brand, vt.name as type_name, v.license_plate
		FROM repair_orders ro
		JOIN vehicles v ON ro.vehicle_id = v.id
		LEFT JOIN vehicle_brands vb ON v.brand_id = vb.id
		LEFT JOIN vehicle_types vt ON vb.type_id = vt.id
		WHERE ro.mechanic_id = $1 AND ro.status IN ('pending', 'in_progress')
		ORDER BY ro.created_at ASC`

	err := r.db.Select(&repairs, query, mechanicID)
	if err != nil {
		return nil, fmt.Errorf("failed to get assigned repairs: %w", err)
	}

	return repairs, nil
}

func (r *dashboardRepository) GetCompletedRepairsToday(mechanicID int, date time.Time) ([]models.RepairOrder, error) {
	dateStr := date.Format("2006-01-02")
	repairs := []models.RepairOrder{}
	query := `
		SELECT ro.*, vb.name as brand, vt.name as type_name, v.license_plate
		FROM repair_orders ro
		JOIN vehicles v ON ro.vehicle_id = v.id
		LEFT JOIN vehicle_brands vb ON v.brand_id = vb.id
		LEFT JOIN vehicle_types vt ON vb.type_id = vt.id
		WHERE ro.mechanic_id = $1 AND ro.status = 'completed' 
		      AND ro.updated_at::date = $2
		ORDER BY ro.updated_at DESC`

	err := r.db.Select(&repairs, query, mechanicID, dateStr)
	if err != nil {
		return nil, fmt.Errorf("failed to get completed repairs today: %w", err)
	}

	return repairs, nil
}

func (r *dashboardRepository) GetRequiredPartsForRepairs(mechanicID int) ([]models.SparePart, error) {
	spareParts := []models.SparePart{}
	query := `
		SELECT DISTINCT sp.*
		FROM spare_parts sp
		JOIN repair_spare_parts rsp ON sp.id = rsp.spare_part_id
		JOIN repair_orders ro ON rsp.repair_order_id = ro.id
		WHERE ro.mechanic_id = $1 AND ro.status IN ('pending', 'in_progress')
		      AND sp.stock_quantity < rsp.quantity_used
		ORDER BY sp.name`

	err := r.db.Select(&spareParts, query, mechanicID)
	if err != nil {
		return nil, fmt.Errorf("failed to get required parts: %w", err)
	}

	return spareParts, nil
}

func (r *dashboardRepository) GetMonthlyStats(month, year int) (*models.MonthlyClosing, error) {
	closing := &models.MonthlyClosing{}
	query := "SELECT * FROM monthly_closings WHERE month = $1 AND year = $2"

	err := r.db.Get(closing, query, month, year)
	if err != nil {
		// If no existing monthly closing, calculate real-time
		return r.calculateMonthlyStats(month, year)
	}

	return closing, nil
}

func (r *dashboardRepository) calculateMonthlyStats(month, year int) (*models.MonthlyClosing, error) {
	closing := &models.MonthlyClosing{
		Month: month,
		Year:  year,
	}

	// Calculate total purchase for the month
	err := r.db.Get(&closing.TotalPurchase,
		`SELECT COALESCE(SUM(purchase_price), 0) FROM purchase_transactions 
		 WHERE EXTRACT(MONTH FROM transaction_date) = $1 AND EXTRACT(YEAR FROM transaction_date) = $2`,
		month, year)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate total purchase: %w", err)
	}

	// Calculate total sales for the month
	err = r.db.Get(&closing.TotalSales,
		`SELECT COALESCE(SUM(selling_price), 0) FROM sales_transactions 
		 WHERE EXTRACT(MONTH FROM transaction_date) = $1 AND EXTRACT(YEAR FROM transaction_date) = $2`,
		month, year)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate total sales: %w", err)
	}

	// Calculate total repair cost for the month
	err = r.db.Get(&closing.TotalRepairCost,
		`SELECT COALESCE(SUM(actual_cost), 0) FROM repair_orders 
		 WHERE EXTRACT(MONTH FROM updated_at) = $1 AND EXTRACT(YEAR FROM updated_at) = $2 
		       AND status = 'completed'`,
		month, year)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate total repair cost: %w", err)
	}

	// Calculate total profit for the month
	err = r.db.Get(&closing.TotalProfit,
		`SELECT COALESCE(SUM(profit), 0) FROM sales_transactions 
		 WHERE EXTRACT(MONTH FROM transaction_date) = $1 AND EXTRACT(YEAR FROM transaction_date) = $2`,
		month, year)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate total profit: %w", err)
	}

	// Count vehicles purchased in the month
	err = r.db.Get(&closing.VehiclesPurchased,
		`SELECT COUNT(*) FROM purchase_transactions 
		 WHERE EXTRACT(MONTH FROM transaction_date) = $1 AND EXTRACT(YEAR FROM transaction_date) = $2`,
		month, year)
	if err != nil {
		return nil, fmt.Errorf("failed to count vehicles purchased: %w", err)
	}

	// Count vehicles sold in the month
	err = r.db.Get(&closing.VehiclesSold,
		`SELECT COUNT(*) FROM sales_transactions 
		 WHERE EXTRACT(MONTH FROM transaction_date) = $1 AND EXTRACT(YEAR FROM transaction_date) = $2`,
		month, year)
	if err != nil {
		return nil, fmt.Errorf("failed to count vehicles sold: %w", err)
	}

	// Count vehicles in stock
	err = r.db.Get(&closing.VehiclesInStock,
		"SELECT COUNT(*) FROM vehicles WHERE status = 'available'")
	if err != nil {
		return nil, fmt.Errorf("failed to count vehicles in stock: %w", err)
	}

	return closing, nil
}

func (r *dashboardRepository) GetTopPerformance() (map[string]interface{}, error) {
	performance := make(map[string]interface{})

	// Get best selling vehicle brands this month
	var topBrand struct {
		Brand string `db:"brand"`
		Count int    `db:"count"`
	}

	err := r.db.Get(&topBrand,
		`SELECT vb.name as brand, COUNT(*) as count
		 FROM sales_transactions st
		 JOIN vehicles v ON st.vehicle_id = v.id
		 JOIN vehicle_brands vb ON v.brand_id = vb.id
		 WHERE EXTRACT(MONTH FROM st.transaction_date) = EXTRACT(MONTH FROM CURRENT_DATE)
		       AND EXTRACT(YEAR FROM st.transaction_date) = EXTRACT(YEAR FROM CURRENT_DATE)
		 GROUP BY vb.name
		 ORDER BY count DESC
		 LIMIT 1`)
	if err == nil {
		performance["top_brand"] = map[string]interface{}{
			"brand": topBrand.Brand,
			"sales": topBrand.Count,
		}
	}

	// Get top performing mechanic this month
	var topMechanic struct {
		MechanicName string `db:"mechanic_name"`
		Count        int    `db:"count"`
	}

	err = r.db.Get(&topMechanic,
		`SELECT u.full_name as mechanic_name, COUNT(*) as count
		 FROM repair_orders ro
		 JOIN users u ON ro.mechanic_id = u.id
		 WHERE EXTRACT(MONTH FROM ro.updated_at) = EXTRACT(MONTH FROM CURRENT_DATE)
		       AND EXTRACT(YEAR FROM ro.updated_at) = EXTRACT(YEAR FROM CURRENT_DATE)
		       AND ro.status = 'completed'
		 GROUP BY u.full_name
		 ORDER BY count DESC
		 LIMIT 1`)
	if err == nil {
		performance["top_mechanic"] = map[string]interface{}{
			"name":    topMechanic.MechanicName,
			"repairs": topMechanic.Count,
		}
	}

	// Get highest profit transaction this month
	var highestProfit struct {
		InvoiceNumber string  `db:"invoice_number"`
		Profit        float64 `db:"profit"`
	}

	err = r.db.Get(&highestProfit,
		`SELECT invoice_number, profit
		 FROM sales_transactions
		 WHERE EXTRACT(MONTH FROM transaction_date) = EXTRACT(MONTH FROM CURRENT_DATE)
		       AND EXTRACT(YEAR FROM transaction_date) = EXTRACT(YEAR FROM CURRENT_DATE)
		 ORDER BY profit DESC
		 LIMIT 1`)
	if err == nil {
		performance["highest_profit"] = map[string]interface{}{
			"invoice": highestProfit.InvoiceNumber,
			"profit":  highestProfit.Profit,
		}
	}

	return performance, nil
}

func (r *dashboardRepository) CreateDailyClosing(userID int, req *models.DailyClosingCreateRequest) (*models.DailyClosing, error) {
	// Calculate totals for the day
	dateStr := req.ClosingDate.Format("2006-01-02")

	closing := &models.DailyClosing{
		ClosingDate: req.ClosingDate,
		CashInHand:  req.CashInHand,
		Notes:       req.Notes,
		ClosedBy:    userID,
		CreatedAt:   time.Now(),
	}

	// Calculate total purchase for the day
	err := r.db.Get(&closing.TotalPurchase,
		"SELECT COALESCE(SUM(purchase_price), 0) FROM purchase_transactions WHERE transaction_date::date = $1",
		dateStr)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate total purchase: %w", err)
	}

	// Calculate total sales for the day
	err = r.db.Get(&closing.TotalSales,
		"SELECT COALESCE(SUM(selling_price), 0) FROM sales_transactions WHERE transaction_date::date = $1",
		dateStr)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate total sales: %w", err)
	}

	// Calculate total repair cost for the day
	err = r.db.Get(&closing.TotalRepairCost,
		"SELECT COALESCE(SUM(actual_cost), 0) FROM repair_orders WHERE updated_at::date = $1 AND status = 'completed'",
		dateStr)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate total repair cost: %w", err)
	}

	// Calculate total profit for the day
	err = r.db.Get(&closing.TotalProfit,
		"SELECT COALESCE(SUM(profit), 0) FROM sales_transactions WHERE transaction_date::date = $1",
		dateStr)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate total profit: %w", err)
	}

	// Insert into database
	query := `
		INSERT INTO daily_closings (closing_date, total_purchase, total_sales, total_repair_cost, 
		                           total_profit, cash_in_hand, notes, closed_by, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING id`

	err = r.db.QueryRow(query, closing.ClosingDate, closing.TotalPurchase, closing.TotalSales,
		closing.TotalRepairCost, closing.TotalProfit, closing.CashInHand, closing.Notes,
		closing.ClosedBy, closing.CreatedAt).Scan(&closing.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to create daily closing: %w", err)
	}

	return closing, nil
}

func (r *dashboardRepository) CreateMonthlyClosing(userID int, req *models.MonthlyClosingCreateRequest) (*models.MonthlyClosing, error) {
	closing := &models.MonthlyClosing{
		Month:     req.Month,
		Year:      req.Year,
		ClosedBy:  userID,
		CreatedAt: time.Now(),
	}

	// Calculate totals for the month
	err := r.db.Get(&closing.TotalPurchase,
		`SELECT COALESCE(SUM(purchase_price), 0) FROM purchase_transactions 
		 WHERE EXTRACT(MONTH FROM transaction_date) = $1 AND EXTRACT(YEAR FROM transaction_date) = $2`,
		req.Month, req.Year)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate total purchase: %w", err)
	}

	err = r.db.Get(&closing.TotalSales,
		`SELECT COALESCE(SUM(selling_price), 0) FROM sales_transactions 
		 WHERE EXTRACT(MONTH FROM transaction_date) = $1 AND EXTRACT(YEAR FROM transaction_date) = $2`,
		req.Month, req.Year)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate total sales: %w", err)
	}

	err = r.db.Get(&closing.TotalRepairCost,
		`SELECT COALESCE(SUM(actual_cost), 0) FROM repair_orders 
		 WHERE EXTRACT(MONTH FROM updated_at) = $1 AND EXTRACT(YEAR FROM updated_at) = $2 
		       AND status = 'completed'`,
		req.Month, req.Year)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate total repair cost: %w", err)
	}

	err = r.db.Get(&closing.TotalProfit,
		`SELECT COALESCE(SUM(profit), 0) FROM sales_transactions 
		 WHERE EXTRACT(MONTH FROM transaction_date) = $1 AND EXTRACT(YEAR FROM transaction_date) = $2`,
		req.Month, req.Year)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate total profit: %w", err)
	}

	err = r.db.Get(&closing.VehiclesPurchased,
		`SELECT COUNT(*) FROM purchase_transactions 
		 WHERE EXTRACT(MONTH FROM transaction_date) = $1 AND EXTRACT(YEAR FROM transaction_date) = $2`,
		req.Month, req.Year)
	if err != nil {
		return nil, fmt.Errorf("failed to count vehicles purchased: %w", err)
	}

	err = r.db.Get(&closing.VehiclesSold,
		`SELECT COUNT(*) FROM sales_transactions 
		 WHERE EXTRACT(MONTH FROM transaction_date) = $1 AND EXTRACT(YEAR FROM transaction_date) = $2`,
		req.Month, req.Year)
	if err != nil {
		return nil, fmt.Errorf("failed to count vehicles sold: %w", err)
	}

	err = r.db.Get(&closing.VehiclesInStock,
		"SELECT COUNT(*) FROM vehicles WHERE status = 'available'")
	if err != nil {
		return nil, fmt.Errorf("failed to count vehicles in stock: %w", err)
	}

	// Insert into database
	query := `
		INSERT INTO monthly_closings (month, year, total_purchase, total_sales, total_repair_cost, 
		                             total_profit, vehicles_purchased, vehicles_sold, vehicles_in_stock,
		                             closed_by, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING id`

	err = r.db.QueryRow(query, closing.Month, closing.Year, closing.TotalPurchase, closing.TotalSales,
		closing.TotalRepairCost, closing.TotalProfit, closing.VehiclesPurchased, closing.VehiclesSold,
		closing.VehiclesInStock, closing.ClosedBy, closing.CreatedAt).Scan(&closing.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to create monthly closing: %w", err)
	}

	return closing, nil
}

func (r *dashboardRepository) UpdateDashboardMetrics(date time.Time) error {
	// Calculate real-time metrics
	metrics, err := r.calculateRealTimeMetrics(date)
	if err != nil {
		return fmt.Errorf("failed to calculate metrics: %w", err)
	}

	// Upsert into dashboard_metrics table
	query := `
		INSERT INTO dashboard_metrics (metric_date, vehicles_available, vehicles_in_repair, 
		                              vehicles_sold_today, revenue_today, profit_today, 
		                              pending_repairs, low_stock_items, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (metric_date) 
		DO UPDATE SET 
			vehicles_available = EXCLUDED.vehicles_available,
			vehicles_in_repair = EXCLUDED.vehicles_in_repair,
			vehicles_sold_today = EXCLUDED.vehicles_sold_today,
			revenue_today = EXCLUDED.revenue_today,
			profit_today = EXCLUDED.profit_today,
			pending_repairs = EXCLUDED.pending_repairs,
			low_stock_items = EXCLUDED.low_stock_items,
			updated_at = EXCLUDED.updated_at`

	_, err = r.db.Exec(query, metrics.MetricDate, metrics.VehiclesAvailable, metrics.VehiclesInRepair,
		metrics.VehiclesSoldToday, metrics.RevenueToday, metrics.ProfitToday,
		metrics.PendingRepairs, metrics.LowStockItems, metrics.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to update dashboard metrics: %w", err)
	}

	return nil
}
