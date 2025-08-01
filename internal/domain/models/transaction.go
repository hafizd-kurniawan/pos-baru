package models

import (
	"time"
)

// PaymentStatus enum
type PaymentStatus string

const (
	PaymentStatusPending PaymentStatus = "pending"
	PaymentStatusPartial PaymentStatus = "partial"
	PaymentStatusPaid    PaymentStatus = "paid"
)

// PurchaseTransaction represents the purchase_transactions table
type PurchaseTransaction struct {
	ID              int           `json:"id" db:"id"`
	InvoiceNumber   string        `json:"invoice_number" db:"invoice_number" validate:"required,max=50"`
	TransactionDate time.Time     `json:"transaction_date" db:"transaction_date" validate:"required"`
	SourceType      SourceType    `json:"source_type" db:"source_type" validate:"required"`
	SourceID        int           `json:"source_id" db:"source_id" validate:"required"`
	VehicleID       int           `json:"vehicle_id" db:"vehicle_id" validate:"required"`
	PurchasePrice   float64       `json:"purchase_price" db:"purchase_price" validate:"required,min=0"`
	PaymentMethod   *string       `json:"payment_method" db:"payment_method" validate:"omitempty,max=50"`
	PaymentStatus   PaymentStatus `json:"payment_status" db:"payment_status"`
	Notes           *string       `json:"notes" db:"notes"`
	ProcessedBy     int           `json:"processed_by" db:"processed_by" validate:"required"`
	CreatedAt       time.Time     `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time     `json:"updated_at" db:"updated_at"`
	Vehicle         *Vehicle      `json:"vehicle,omitempty"`
	Processor       *User         `json:"processor,omitempty"`
	Customer        *Customer     `json:"customer,omitempty"`
	Supplier        *Supplier     `json:"supplier,omitempty"`
}

// SalesTransaction represents the sales_transactions table
type SalesTransaction struct {
	ID               int           `json:"id" db:"id"`
	InvoiceNumber    string        `json:"invoice_number" db:"invoice_number" validate:"required,max=50"`
	TransactionDate  time.Time     `json:"transaction_date" db:"transaction_date" validate:"required"`
	CustomerID       int           `json:"customer_id" db:"customer_id" validate:"required"`
	VehicleID        int           `json:"vehicle_id" db:"vehicle_id" validate:"required"`
	HPPPrice         float64       `json:"hpp_price" db:"hpp_price" validate:"required,min=0"`
	SellingPrice     float64       `json:"selling_price" db:"selling_price" validate:"required,min=0"`
	Profit           float64       `json:"profit" db:"profit" validate:"min=0"`
	PaymentMethod    *string       `json:"payment_method" db:"payment_method" validate:"omitempty,max=50"`
	PaymentStatus    PaymentStatus `json:"payment_status" db:"payment_status"`
	DownPayment      float64       `json:"down_payment" db:"down_payment" validate:"min=0"`
	RemainingPayment float64       `json:"remaining_payment" db:"remaining_payment" validate:"min=0"`
	Notes            *string       `json:"notes" db:"notes"`
	ProcessedBy      int           `json:"processed_by" db:"processed_by" validate:"required"`
	CreatedAt        time.Time     `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time     `json:"updated_at" db:"updated_at"`
	Vehicle          *Vehicle      `json:"vehicle,omitempty"`
	Customer         *Customer     `json:"customer,omitempty"`
	Processor        *User         `json:"processor,omitempty"`
}

// PurchaseTransactionCreateRequest for creating new purchase transaction
type PurchaseTransactionCreateRequest struct {
	SourceType      SourceType    `json:"source_type" validate:"required"`
	SourceID        int           `json:"source_id" validate:"required"`
	VehicleID       int           `json:"vehicle_id" validate:"required"`
	PurchasePrice   float64       `json:"purchase_price" validate:"required,min=0"`
	PaymentMethod   *string       `json:"payment_method" validate:"omitempty,max=50"`
	PaymentStatus   PaymentStatus `json:"payment_status"`
	Notes           *string       `json:"notes"`
}

// SalesTransactionCreateRequest for creating new sales transaction
type SalesTransactionCreateRequest struct {
	CustomerID       int           `json:"customer_id" validate:"required"`
	VehicleID        int           `json:"vehicle_id" validate:"required"`
	SellingPrice     float64       `json:"selling_price" validate:"required,min=0"`
	PaymentMethod    *string       `json:"payment_method" validate:"omitempty,max=50"`
	PaymentStatus    PaymentStatus `json:"payment_status"`
	DownPayment      float64       `json:"down_payment" validate:"min=0"`
	Notes            *string       `json:"notes"`
}

// PaymentUpdateRequest for updating payment status
type PaymentUpdateRequest struct {
	PaymentStatus    PaymentStatus `json:"payment_status" validate:"required"`
	DownPayment      *float64      `json:"down_payment" validate:"omitempty,min=0"`
	RemainingPayment *float64      `json:"remaining_payment" validate:"omitempty,min=0"`
	Notes            *string       `json:"notes"`
}