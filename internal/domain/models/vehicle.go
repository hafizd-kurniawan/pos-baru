package models

import (
	"time"
)

// VehicleType represents the vehicle_types table
type VehicleType struct {
	ID          int       `json:"id" db:"id"`
	Name        string    `json:"name" db:"name" validate:"required,max=100"`
	Description *string   `json:"description" db:"description"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

// VehicleTypeCreateRequest for creating new vehicle type
type VehicleTypeCreateRequest struct {
	Name        string  `json:"name" validate:"required,max=100"`
	Description *string `json:"description"`
}

// VehicleTypeUpdateRequest for updating vehicle type
type VehicleTypeUpdateRequest struct {
	Name        *string `json:"name" validate:"omitempty,max=100"`
	Description *string `json:"description"`
}

// VehicleBrand represents the vehicle_brands table
type VehicleBrand struct {
	ID          int          `json:"id" db:"id"`
	Name        string       `json:"name" db:"name" validate:"required,max=100"`
	TypeID      int          `json:"type_id" db:"type_id" validate:"required"`
	CreatedAt   time.Time    `json:"created_at" db:"created_at"`
	VehicleType *VehicleType `json:"vehicle_type,omitempty"`
}

// VehicleBrandCreateRequest for creating new vehicle brand
type VehicleBrandCreateRequest struct {
	Name   string `json:"name" validate:"required,max=100"`
	TypeID int    `json:"type_id" validate:"required"`
}

// VehicleBrandUpdateRequest for updating vehicle brand
type VehicleBrandUpdateRequest struct {
	Name   *string `json:"name" validate:"omitempty,max=100"`
	TypeID *int    `json:"type_id"`
}

// SourceType enum
type SourceType string

const (
	SourceTypeCustomer SourceType = "customer"
	SourceTypeSupplier SourceType = "supplier"
)

// ConditionStatus enum
type ConditionStatus string

const (
	ConditionExcellent   ConditionStatus = "excellent"
	ConditionGood        ConditionStatus = "good"
	ConditionFair        ConditionStatus = "fair"
	ConditionPoor        ConditionStatus = "poor"
	ConditionNeedsRepair ConditionStatus = "needs_repair"
)

// VehicleStatus enum
type VehicleStatus string

const (
	VehicleStatusAvailable VehicleStatus = "available"
	VehicleStatusInRepair  VehicleStatus = "in_repair"
	VehicleStatusSold      VehicleStatus = "sold"
	VehicleStatusReserved  VehicleStatus = "reserved"
)

// Vehicle represents the vehicles table
type Vehicle struct {
	ID               int             `json:"id" db:"id"`
	Code             string          `json:"code" db:"code" validate:"required,max=50"`
	BrandID          int             `json:"brand_id" db:"brand_id" validate:"required"`
	Model            string          `json:"model" db:"model" validate:"required,max=100"`
	Year             int             `json:"year" db:"year" validate:"required,min=1980"`
	Color            *string         `json:"color" db:"color" validate:"omitempty,max=50"`
	EngineCapacity   *string         `json:"engine_capacity" db:"engine_capacity" validate:"omitempty,max=20"`
	FuelType         *string         `json:"fuel_type" db:"fuel_type" validate:"omitempty,max=20"`
	TransmissionType *string         `json:"transmission_type" db:"transmission_type" validate:"omitempty,max=20"`
	LicensePlate     *string         `json:"license_plate" db:"license_plate" validate:"omitempty,max=20"`
	ChassisNumber    *string         `json:"chassis_number" db:"chassis_number" validate:"omitempty,max=100"`
	EngineNumber     *string         `json:"engine_number" db:"engine_number" validate:"omitempty,max=100"`
	Odometer         int             `json:"odometer" db:"odometer"`
	SourceType       SourceType      `json:"source_type" db:"source_type" validate:"required"`
	SourceID         *int            `json:"source_id" db:"source_id"`
	PurchasePrice    float64         `json:"purchase_price" db:"purchase_price" validate:"required,min=0"`
	ConditionStatus  ConditionStatus `json:"condition_status" db:"condition_status" validate:"required"`
	Status           VehicleStatus   `json:"status" db:"status"`
	RepairCost       *float64        `json:"repair_cost" db:"repair_cost"`
	HPPPrice         *float64        `json:"hpp_price" db:"hpp_price"`
	SellingPrice     *float64        `json:"selling_price" db:"selling_price"`
	SoldPrice        *float64        `json:"sold_price" db:"sold_price"`
	SoldDate         *time.Time      `json:"sold_date" db:"sold_date"`
	Notes            *string         `json:"notes" db:"notes"`
	CreatedBy        int             `json:"created_by" db:"created_by" validate:"required"`
	CreatedAt        time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time       `json:"updated_at" db:"updated_at"`
	Brand            *VehicleBrand   `json:"brand,omitempty"`
	Creator          *User           `json:"creator,omitempty"`
	Photos           []VehiclePhoto  `json:"photos,omitempty"`
}

// VehiclePhoto represents the vehicle_photos table
type VehiclePhoto struct {
	ID        int       `json:"id" db:"id"`
	VehicleID int       `json:"vehicle_id" db:"vehicle_id" validate:"required"`
	PhotoPath string    `json:"photo_path" db:"photo_path" validate:"required,max=255"`
	IsPrimary bool      `json:"is_primary" db:"is_primary"`
	Caption   *string   `json:"caption" db:"caption" validate:"omitempty,max=255"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// VehicleCreateRequest for creating new vehicle
type VehicleCreateRequest struct {
	Code             string          `json:"code" validate:"required,max=50"`
	BrandID          int             `json:"brand_id" validate:"required"`
	Model            string          `json:"model" validate:"required,max=100"`
	Year             int             `json:"year" validate:"required,min=1980"`
	Color            *string         `json:"color" validate:"omitempty,max=50"`
	EngineCapacity   *string         `json:"engine_capacity" validate:"omitempty,max=20"`
	FuelType         *string         `json:"fuel_type" validate:"omitempty,max=20"`
	TransmissionType *string         `json:"transmission_type" validate:"omitempty,max=20"`
	LicensePlate     *string         `json:"license_plate" validate:"omitempty,max=20"`
	ChassisNumber    *string         `json:"chassis_number" validate:"omitempty,max=100"`
	EngineNumber     *string         `json:"engine_number" validate:"omitempty,max=100"`
	Odometer         int             `json:"odometer"`
	SourceType       SourceType      `json:"source_type" validate:"required"`
	SourceID         *int            `json:"source_id"`
	PurchasePrice    float64         `json:"purchase_price" validate:"required,min=0"`
	ConditionStatus  ConditionStatus `json:"condition_status" validate:"required"`
	Notes            *string         `json:"notes"`
}

// VehicleUpdateRequest for updating vehicle
type VehicleUpdateRequest struct {
	Model            *string          `json:"model" validate:"omitempty,max=100"`
	Year             *int             `json:"year" validate:"omitempty,min=1980"`
	Color            *string          `json:"color" validate:"omitempty,max=50"`
	EngineCapacity   *string          `json:"engine_capacity" validate:"omitempty,max=20"`
	FuelType         *string          `json:"fuel_type" validate:"omitempty,max=20"`
	TransmissionType *string          `json:"transmission_type" validate:"omitempty,max=20"`
	LicensePlate     *string          `json:"license_plate" validate:"omitempty,max=20"`
	ChassisNumber    *string          `json:"chassis_number" validate:"omitempty,max=100"`
	EngineNumber     *string          `json:"engine_number" validate:"omitempty,max=100"`
	Odometer         *int             `json:"odometer"`
	ConditionStatus  *ConditionStatus `json:"condition_status"`
	Status           *VehicleStatus   `json:"status"`
	SellingPrice     *float64         `json:"selling_price" validate:"omitempty,min=0"`
	Notes            *string          `json:"notes"`
}

// VehicleSearchFilters represents the search filters for vehicles
type VehicleSearchFilters struct {
	BrandID     *int     `form:"brand_id" json:"brand_id,omitempty"`
	Model       string   `form:"model" json:"model,omitempty"`
	YearMin     *int     `form:"year_min" json:"year_min,omitempty"`
	YearMax     *int     `form:"year_max" json:"year_max,omitempty"`
	Color       string   `form:"color" json:"color,omitempty"`
	OdometerMin *int     `form:"odometer_min" json:"odometer_min,omitempty"`
	OdometerMax *int     `form:"odometer_max" json:"odometer_max,omitempty"`
	PriceMin    *float64 `form:"price_min" json:"price_min,omitempty"`
	PriceMax    *float64 `form:"price_max" json:"price_max,omitempty"`
	Status      string   `form:"status" json:"status,omitempty"`
}
