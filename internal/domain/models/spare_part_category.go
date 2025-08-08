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
