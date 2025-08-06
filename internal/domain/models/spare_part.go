package models

import (
	"time"
)

// SparePart represents the spare_parts table
type SparePart struct {
	ID            int       `json:"id" db:"id"`
	Code          string    `json:"code" db:"code" validate:"required,max=50"`
	Name          string    `json:"name" db:"name" validate:"required,max=150"`
	Description   *string   `json:"description" db:"description"`
	Category      string    `json:"category" db:"category" validate:"required,max=50"`
	Unit          string    `json:"unit" db:"unit" validate:"required,max=20"`
	PurchasePrice float64   `json:"purchase_price" db:"purchase_price" validate:"min=0"`
	SellingPrice  float64   `json:"selling_price" db:"selling_price" validate:"min=0"`
	StockQuantity int       `json:"stock_quantity" db:"stock_quantity" validate:"min=0"`
	MinimumStock  int       `json:"minimum_stock" db:"minimum_stock" validate:"min=0"`
	IsActive      bool      `json:"is_active" db:"is_active"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time `json:"updated_at" db:"updated_at"`
}

// SparePartCreateRequest for creating new spare part
type SparePartCreateRequest struct {
	Code          string  `json:"code" validate:"required,max=50"`
	Name          string  `json:"name" validate:"required,max=150"`
	Description   *string `json:"description"`
	Category      string  `json:"category" validate:"required,max=50"`
	Unit          string  `json:"unit" validate:"required,max=20"`
	PurchasePrice float64 `json:"purchase_price" validate:"min=0"`
	SellingPrice  float64 `json:"selling_price" validate:"min=0"`
	StockQuantity int     `json:"stock_quantity" validate:"min=0"`
	MinimumStock  int     `json:"minimum_stock" validate:"min=0"`
}

// SparePartUpdateRequest for updating spare part
type SparePartUpdateRequest struct {
	Name          *string  `json:"name" validate:"omitempty,max=150"`
	Description   *string  `json:"description"`
	Category      *string  `json:"category" validate:"omitempty,max=50"`
	Unit          *string  `json:"unit" validate:"omitempty,max=20"`
	PurchasePrice *float64 `json:"purchase_price" validate:"omitempty,min=0"`
	SellingPrice  *float64 `json:"selling_price" validate:"omitempty,min=0"`
	StockQuantity *int     `json:"stock_quantity" validate:"omitempty,min=0"`
	MinimumStock  *int     `json:"minimum_stock" validate:"omitempty,min=0"`
	IsActive      *bool    `json:"is_active"`
}

// SparePartStockUpdate for updating spare part stock
type SparePartStockUpdate struct {
	Quantity  int    `json:"quantity" validate:"required"`
	Operation string `json:"operation" validate:"required,oneof=add subtract"` // "add" or "subtract"
	Notes     string `json:"notes" validate:"omitempty,max=255"`
}
