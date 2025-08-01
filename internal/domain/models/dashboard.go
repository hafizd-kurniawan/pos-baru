package models

import (
	"time"
)

// DailyClosing represents the daily_closings table
type DailyClosing struct {
	ID              int       `json:"id" db:"id"`
	ClosingDate     time.Time `json:"closing_date" db:"closing_date" validate:"required"`
	TotalPurchase   float64   `json:"total_purchase" db:"total_purchase"`
	TotalSales      float64   `json:"total_sales" db:"total_sales"`
	TotalRepairCost float64   `json:"total_repair_cost" db:"total_repair_cost"`
	TotalProfit     float64   `json:"total_profit" db:"total_profit"`
	CashInHand      float64   `json:"cash_in_hand" db:"cash_in_hand"`
	Notes           *string   `json:"notes" db:"notes"`
	ClosedBy        int       `json:"closed_by" db:"closed_by" validate:"required"`
	CreatedAt       time.Time `json:"created_at" db:"created_at"`
	Closer          *User     `json:"closer,omitempty"`
}

// MonthlyClosing represents the monthly_closings table
type MonthlyClosing struct {
	ID                int       `json:"id" db:"id"`
	Month             int       `json:"month" db:"month" validate:"required,min=1,max=12"`
	Year              int       `json:"year" db:"year" validate:"required,min=2020"`
	TotalPurchase     float64   `json:"total_purchase" db:"total_purchase"`
	TotalSales        float64   `json:"total_sales" db:"total_sales"`
	TotalRepairCost   float64   `json:"total_repair_cost" db:"total_repair_cost"`
	TotalProfit       float64   `json:"total_profit" db:"total_profit"`
	VehiclesPurchased int       `json:"vehicles_purchased" db:"vehicles_purchased"`
	VehiclesSold      int       `json:"vehicles_sold" db:"vehicles_sold"`
	VehiclesInStock   int       `json:"vehicles_in_stock" db:"vehicles_in_stock"`
	ClosedBy          int       `json:"closed_by" db:"closed_by" validate:"required"`
	CreatedAt         time.Time `json:"created_at" db:"created_at"`
	Closer            *User     `json:"closer,omitempty"`
}

// DashboardMetric represents the dashboard_metrics table
type DashboardMetric struct {
	ID                int       `json:"id" db:"id"`
	MetricDate        time.Time `json:"metric_date" db:"metric_date" validate:"required"`
	VehiclesAvailable int       `json:"vehicles_available" db:"vehicles_available"`
	VehiclesInRepair  int       `json:"vehicles_in_repair" db:"vehicles_in_repair"`
	VehiclesSoldToday int       `json:"vehicles_sold_today" db:"vehicles_sold_today"`
	RevenueToday      float64   `json:"revenue_today" db:"revenue_today"`
	ProfitToday       float64   `json:"profit_today" db:"profit_today"`
	PendingRepairs    int       `json:"pending_repairs" db:"pending_repairs"`
	LowStockItems     int       `json:"low_stock_items" db:"low_stock_items"`
	UpdatedAt         time.Time `json:"updated_at" db:"updated_at"`
}

// DailyClosingCreateRequest for creating daily closing
type DailyClosingCreateRequest struct {
	ClosingDate time.Time `json:"closing_date" validate:"required"`
	CashInHand  float64   `json:"cash_in_hand" validate:"min=0"`
	Notes       *string   `json:"notes"`
}

// MonthlyClosingCreateRequest for creating monthly closing
type MonthlyClosingCreateRequest struct {
	Month int     `json:"month" validate:"required,min=1,max=12"`
	Year  int     `json:"year" validate:"required,min=2020"`
	Notes *string `json:"notes"`
}

// DashboardResponse for dashboard API response
type DashboardResponse struct {
	Overview          DashboardMetric      `json:"overview"`
	RecentTransactions []interface{}       `json:"recent_transactions"`
	PendingRepairs    []RepairOrder       `json:"pending_repairs"`
	LowStockItems     []SparePart         `json:"low_stock_items"`
	AvailableVehicles []Vehicle           `json:"available_vehicles"`
}

// AdminDashboardResponse for admin specific dashboard
type AdminDashboardResponse struct {
	DashboardResponse
	MonthlyStats      MonthlyClosing      `json:"monthly_stats"`
	TopPerformance    map[string]interface{} `json:"top_performance"`
}

// CashierDashboardResponse for cashier specific dashboard
type CashierDashboardResponse struct {
	DashboardResponse
	TodayTransactions []interface{} `json:"today_transactions"`
	PendingPayments   []interface{} `json:"pending_payments"`
}

// MechanicDashboardResponse for mechanic specific dashboard
type MechanicDashboardResponse struct {
	AssignedRepairs  []RepairOrder `json:"assigned_repairs"`
	CompletedToday   []RepairOrder `json:"completed_today"`
	RequiredParts    []SparePart   `json:"required_parts"`
}