package models

import "time"

type SparePartCategory struct {
	ID          int       `json:"id" db:"id"`
	Name        string    `json:"name" db:"name"`
	Description *string   `json:"description" db:"description"`
	IsActive    bool      `json:"is_active" db:"is_active"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

type SparePartCategoryCreateRequest struct {
	Name        string  `json:"name" binding:"required"`
	Description *string `json:"description"`
	IsActive    bool    `json:"is_active"`
}

type SparePartCategoryUpdateRequest struct {
	Name        *string `json:"name"`
	Description *string `json:"description"`
	IsActive    *bool   `json:"is_active"`
}

// CategoryInfo contains category information with spare parts count
type CategoryInfo struct {
	ID             int       `json:"id" db:"id"`
	Name           string    `json:"name" db:"name"`
	Description    string    `json:"description" db:"description"`
	SparePartCount int       `json:"spare_part_count" db:"spare_part_count"`
	IsActive       bool      `json:"is_active" db:"is_active"`
	CreatedAt      time.Time `json:"created_at" db:"created_at"`
	UpdatedAt      time.Time `json:"updated_at" db:"updated_at"`
}

// CategoryStats contains category statistics
type CategoryStats struct {
	Name           string  `json:"name"`
	SparePartCount int     `json:"spare_part_count"`
	TotalStock     int     `json:"total_stock"`
	LowStockCount  int     `json:"low_stock_count"`
	TotalValue     float64 `json:"total_value"`
	AvgPrice       float64 `json:"avg_price"`
}
