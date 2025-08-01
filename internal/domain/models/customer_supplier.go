package models

import (
	"time"
)

// Supplier represents the suppliers table
type Supplier struct {
	ID            int       `json:"id" db:"id"`
	Name          string    `json:"name" db:"name" validate:"required,max=150"`
	ContactPerson *string   `json:"contact_person" db:"contact_person" validate:"omitempty,max=100"`
	Phone         *string   `json:"phone" db:"phone" validate:"omitempty,max=20"`
	Email         *string   `json:"email" db:"email" validate:"omitempty,email,max=100"`
	Address       *string   `json:"address" db:"address"`
	IsActive      bool      `json:"is_active" db:"is_active"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time `json:"updated_at" db:"updated_at"`
}

// Customer represents the customers table
type Customer struct {
	ID           int       `json:"id" db:"id"`
	Name         string    `json:"name" db:"name" validate:"required,max=150"`
	Phone        *string   `json:"phone" db:"phone" validate:"omitempty,max=20"`
	Email        *string   `json:"email" db:"email" validate:"omitempty,email,max=100"`
	Address      *string   `json:"address" db:"address"`
	IDCardNumber *string   `json:"id_card_number" db:"id_card_number" validate:"omitempty,max=50"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
}

// SupplierCreateRequest for creating new supplier
type SupplierCreateRequest struct {
	Name          string  `json:"name" validate:"required,max=150"`
	ContactPerson *string `json:"contact_person" validate:"omitempty,max=100"`
	Phone         *string `json:"phone" validate:"omitempty,max=20"`
	Email         *string `json:"email" validate:"omitempty,email,max=100"`
	Address       *string `json:"address"`
}

// SupplierUpdateRequest for updating supplier
type SupplierUpdateRequest struct {
	Name          *string `json:"name" validate:"omitempty,max=150"`
	ContactPerson *string `json:"contact_person" validate:"omitempty,max=100"`
	Phone         *string `json:"phone" validate:"omitempty,max=20"`
	Email         *string `json:"email" validate:"omitempty,email,max=100"`
	Address       *string `json:"address"`
	IsActive      *bool   `json:"is_active"`
}

// CustomerCreateRequest for creating new customer
type CustomerCreateRequest struct {
	Name         string  `json:"name" validate:"required,max=150"`
	Phone        *string `json:"phone" validate:"omitempty,max=20"`
	Email        *string `json:"email" validate:"omitempty,email,max=100"`
	Address      *string `json:"address"`
	IDCardNumber *string `json:"id_card_number" validate:"omitempty,max=50"`
}

// CustomerUpdateRequest for updating customer
type CustomerUpdateRequest struct {
	Name         *string `json:"name" validate:"omitempty,max=150"`
	Phone        *string `json:"phone" validate:"omitempty,max=20"`
	Email        *string `json:"email" validate:"omitempty,email,max=100"`
	Address      *string `json:"address"`
	IDCardNumber *string `json:"id_card_number" validate:"omitempty,max=50"`
}