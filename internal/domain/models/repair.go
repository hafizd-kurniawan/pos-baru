package models

import (
	"time"
)

// RepairStatus enum
type RepairStatus string

const (
	RepairStatusPending    RepairStatus = "pending"
	RepairStatusInProgress RepairStatus = "in_progress"
	RepairStatusCompleted  RepairStatus = "completed"
	RepairStatusCancelled  RepairStatus = "cancelled"
)

// RepairOrder represents the repair_orders table
type RepairOrder struct {
	ID            int          `json:"id" db:"id"`
	Code          string       `json:"code" db:"code" validate:"required,max=50"`
	VehicleID     int          `json:"vehicle_id" db:"vehicle_id" validate:"required"`
	MechanicID    int          `json:"mechanic_id" db:"mechanic_id" validate:"required"`
	AssignedBy    int          `json:"assigned_by" db:"assigned_by" validate:"required"`
	Description   *string      `json:"description" db:"description"`
	EstimatedCost float64      `json:"estimated_cost" db:"estimated_cost" validate:"min=0"`
	ActualCost    float64      `json:"actual_cost" db:"actual_cost" validate:"min=0"`
	Status        RepairStatus `json:"status" db:"status"`
	StartedAt     *time.Time   `json:"started_at" db:"started_at"`
	CompletedAt   *time.Time   `json:"completed_at" db:"completed_at"`
	Notes         *string      `json:"notes" db:"notes"`
	CreatedAt     time.Time    `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time    `json:"updated_at" db:"updated_at"`
	// Additional fields for joined queries
	Brand        *string `json:"brand,omitempty" db:"brand"`
	TypeName     *string `json:"type_name,omitempty" db:"type_name"`
	LicensePlate *string `json:"license_plate,omitempty" db:"license_plate"`
	MechanicName *string `json:"mechanic_name,omitempty" db:"mechanic_name"`
	// Relationships
	Vehicle    *Vehicle          `json:"vehicle,omitempty"`
	Mechanic   *User             `json:"mechanic,omitempty"`
	Assigner   *User             `json:"assigner,omitempty"`
	SpareParts []RepairSparePart `json:"spare_parts,omitempty"`
}

// RepairSparePart represents the repair_spare_parts table
type RepairSparePart struct {
	ID            int        `json:"id" db:"id"`
	RepairOrderID int        `json:"repair_order_id" db:"repair_order_id" validate:"required"`
	SparePartID   int        `json:"spare_part_id" db:"spare_part_id" validate:"required"`
	QuantityUsed  int        `json:"quantity_used" db:"quantity_used" validate:"required,min=1"`
	UnitPrice     float64    `json:"unit_price" db:"unit_price" validate:"required,min=0"`
	TotalPrice    float64    `json:"total_price" db:"total_price" validate:"required,min=0"`
	CreatedAt     time.Time  `json:"created_at" db:"created_at"`
	SparePart     *SparePart `json:"spare_part,omitempty"`
}

// RepairOrderCreateRequest for creating new repair order
type RepairOrderCreateRequest struct {
	Code          string  `json:"code" validate:"required,max=50"`
	VehicleID     int     `json:"vehicle_id" validate:"required"`
	MechanicID    int     `json:"mechanic_id" validate:"required"`
	Description   *string `json:"description"`
	EstimatedCost float64 `json:"estimated_cost" validate:"min=0"`
	Notes         *string `json:"notes"`
}

// RepairOrderUpdateRequest for updating repair order
type RepairOrderUpdateRequest struct {
	Description   *string       `json:"description"`
	EstimatedCost *float64      `json:"estimated_cost" validate:"omitempty,min=0"`
	ActualCost    *float64      `json:"actual_cost" validate:"omitempty,min=0"`
	Status        *RepairStatus `json:"status"`
	Notes         *string       `json:"notes"`
}

// RepairSparePartCreateRequest for adding spare part to repair order
type RepairSparePartCreateRequest struct {
	SparePartID  int `json:"spare_part_id" validate:"required"`
	QuantityUsed int `json:"quantity_used" validate:"required,min=1"`
}

// RepairProgressUpdateRequest for updating repair progress
type RepairProgressUpdateRequest struct {
	Status     RepairStatus                   `json:"status" validate:"required"`
	ActualCost *float64                       `json:"actual_cost" validate:"omitempty,min=0"`
	Notes      *string                        `json:"notes"`
	SpareParts []RepairSparePartCreateRequest `json:"spare_parts,omitempty"`
}

// RepairOrderFilter for filtering repair orders
type RepairOrderFilter struct {
	Status     RepairStatus `form:"status"`
	MechanicID int          `form:"mechanic_id"`
	VehicleID  int          `form:"vehicle_id"`
	DateFrom   string       `form:"date_from"`
	DateTo     string       `form:"date_to"`
}
