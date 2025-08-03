package models

import (
	"time"
)

// Role represents the roles table
type Role struct {
	ID          int       `json:"id" db:"id"`
	Name        string    `json:"name" db:"name" validate:"required,max=50"`
	Description *string   `json:"description" db:"description"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

// User represents the users table
type User struct {
	ID        int       `json:"id" db:"id"`
	Username  string    `json:"username" db:"username" validate:"required,max=100"`
	Email     string    `json:"email" db:"email" validate:"required,email,max=100"`
	Password  string    `json:"-" db:"password" validate:"required,min=6"`
	FullName  string    `json:"full_name" db:"full_name" validate:"required,max=150"`
	Phone     *string   `json:"phone" db:"phone" validate:"omitempty,max=20"`
	RoleID    int       `json:"role_id" db:"role_id" validate:"required"`
	IsActive  bool      `json:"is_active" db:"is_active"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
	Role      *Role     `json:"role,omitempty"`
}

// UserCreateRequest for creating new user
type UserCreateRequest struct {
	Username string  `json:"username" validate:"required,max=100"`
	Email    string  `json:"email" validate:"required,email,max=100"`
	Password string  `json:"password" validate:"required,min=6"`
	FullName string  `json:"full_name" validate:"required,max=150"`
	Phone    *string `json:"phone" validate:"omitempty,max=20"`
	RoleID   int     `json:"role_id" validate:"required"`
}

// UserUpdateRequest for updating user
type UserUpdateRequest struct {
	Username *string `json:"username" validate:"omitempty,max=100"`
	Email    *string `json:"email" validate:"omitempty,email,max=100"`
	FullName *string `json:"full_name" validate:"omitempty,max=150"`
	Phone    *string `json:"phone" validate:"omitempty,max=20"`
	RoleID   *int    `json:"role_id" validate:"omitempty"`
	IsActive *bool   `json:"is_active"`
}

// LoginRequest for user authentication
type LoginRequest struct {
	Username string `json:"username" validate:"required"`
	Password string `json:"password" validate:"required"`
}

// LoginResponse for authentication response
type LoginResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}