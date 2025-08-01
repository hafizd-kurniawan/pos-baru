package repository

import (
	"database/sql"
	"fmt"
	"strings"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/pkg/database"
)

type VehicleRepository interface {
	Create(req *models.VehicleCreateRequest, createdBy int) (*models.Vehicle, error)
	GetByID(id int) (*models.Vehicle, error)
	GetByCode(code string) (*models.Vehicle, error)
	Update(id int, req *models.VehicleUpdateRequest) (*models.Vehicle, error)
	Delete(id int) error
	List(page, limit int, status *models.VehicleStatus) ([]models.Vehicle, int64, error)
	GetAvailableVehicles(page, limit int) ([]models.Vehicle, int64, error)
	GetVehiclesInRepair(page, limit int) ([]models.Vehicle, int64, error)
	UpdateStatus(id int, status models.VehicleStatus) error
	UpdateHPPPrice(id int, hppPrice float64) error
	UpdateSellingPrice(id int, sellingPrice float64) error
	UpdateRepairCost(id int, repairCost float64) error
	MarkAsSold(id int, soldPrice float64) error
}

type vehicleRepository struct {
	db *database.Database
}

func NewVehicleRepository(db *database.Database) VehicleRepository {
	return &vehicleRepository{db: db}
}

func (r *vehicleRepository) Create(req *models.VehicleCreateRequest, createdBy int) (*models.Vehicle, error) {
	query := `
		INSERT INTO vehicles (
			code, brand_id, model, year, color, engine_capacity, fuel_type, 
			transmission_type, license_plate, chassis_number, engine_number, 
			odometer, source_type, source_id, purchase_price, condition_status, 
			notes, created_by
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
		RETURNING id, code, brand_id, model, year, color, engine_capacity, fuel_type,
				  transmission_type, license_plate, chassis_number, engine_number,
				  odometer, source_type, source_id, purchase_price, condition_status,
				  status, repair_cost, hpp_price, selling_price, sold_price, sold_date,
				  notes, created_by, created_at, updated_at`

	var vehicle models.Vehicle
	err := r.db.Get(&vehicle, query,
		req.Code, req.BrandID, req.Model, req.Year, req.Color, req.EngineCapacity,
		req.FuelType, req.TransmissionType, req.LicensePlate, req.ChassisNumber,
		req.EngineNumber, req.Odometer, req.SourceType, req.SourceID,
		req.PurchasePrice, req.ConditionStatus, req.Notes, createdBy)
	if err != nil {
		return nil, fmt.Errorf("failed to create vehicle: %w", err)
	}

	return &vehicle, nil
}

func (r *vehicleRepository) GetByID(id int) (*models.Vehicle, error) {
	query := `
		SELECT 
			v.id, v.code, v.brand_id, v.model, v.year, v.color, v.engine_capacity,
			v.fuel_type, v.transmission_type, v.license_plate, v.chassis_number,
			v.engine_number, v.odometer, v.source_type, v.source_id, v.purchase_price,
			v.condition_status, v.status, v.repair_cost, v.hpp_price, v.selling_price,
			v.sold_price, v.sold_date, v.notes, v.created_by, v.created_at, v.updated_at,
			vb.id as "brand.id", vb.name as "brand.name", vb.type_id as "brand.type_id", vb.created_at as "brand.created_at",
			vt.id as "brand.vehicle_type.id", vt.name as "brand.vehicle_type.name", vt.description as "brand.vehicle_type.description", vt.created_at as "brand.vehicle_type.created_at"
		FROM vehicles v
		JOIN vehicle_brands vb ON v.brand_id = vb.id
		JOIN vehicle_types vt ON vb.type_id = vt.id
		WHERE v.id = $1`

	var vehicle models.Vehicle
	err := r.db.Get(&vehicle, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("vehicle not found")
		}
		return nil, fmt.Errorf("failed to get vehicle: %w", err)
	}

	return &vehicle, nil
}

func (r *vehicleRepository) GetByCode(code string) (*models.Vehicle, error) {
	query := `
		SELECT 
			v.id, v.code, v.brand_id, v.model, v.year, v.color, v.engine_capacity,
			v.fuel_type, v.transmission_type, v.license_plate, v.chassis_number,
			v.engine_number, v.odometer, v.source_type, v.source_id, v.purchase_price,
			v.condition_status, v.status, v.repair_cost, v.hpp_price, v.selling_price,
			v.sold_price, v.sold_date, v.notes, v.created_by, v.created_at, v.updated_at
		FROM vehicles v
		WHERE v.code = $1`

	var vehicle models.Vehicle
	err := r.db.Get(&vehicle, query, code)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("vehicle not found")
		}
		return nil, fmt.Errorf("failed to get vehicle: %w", err)
	}

	return &vehicle, nil
}

func (r *vehicleRepository) Update(id int, req *models.VehicleUpdateRequest) (*models.Vehicle, error) {
	// Build dynamic update query
	setParts := []string{"updated_at = CURRENT_TIMESTAMP"}
	args := []interface{}{}
	argCounter := 1

	if req.Model != nil {
		setParts = append(setParts, fmt.Sprintf("model = $%d", argCounter))
		args = append(args, *req.Model)
		argCounter++
	}
	if req.Year != nil {
		setParts = append(setParts, fmt.Sprintf("year = $%d", argCounter))
		args = append(args, *req.Year)
		argCounter++
	}
	if req.Color != nil {
		setParts = append(setParts, fmt.Sprintf("color = $%d", argCounter))
		args = append(args, *req.Color)
		argCounter++
	}
	if req.EngineCapacity != nil {
		setParts = append(setParts, fmt.Sprintf("engine_capacity = $%d", argCounter))
		args = append(args, *req.EngineCapacity)
		argCounter++
	}
	if req.FuelType != nil {
		setParts = append(setParts, fmt.Sprintf("fuel_type = $%d", argCounter))
		args = append(args, *req.FuelType)
		argCounter++
	}
	if req.TransmissionType != nil {
		setParts = append(setParts, fmt.Sprintf("transmission_type = $%d", argCounter))
		args = append(args, *req.TransmissionType)
		argCounter++
	}
	if req.LicensePlate != nil {
		setParts = append(setParts, fmt.Sprintf("license_plate = $%d", argCounter))
		args = append(args, *req.LicensePlate)
		argCounter++
	}
	if req.ChassisNumber != nil {
		setParts = append(setParts, fmt.Sprintf("chassis_number = $%d", argCounter))
		args = append(args, *req.ChassisNumber)
		argCounter++
	}
	if req.EngineNumber != nil {
		setParts = append(setParts, fmt.Sprintf("engine_number = $%d", argCounter))
		args = append(args, *req.EngineNumber)
		argCounter++
	}
	if req.Odometer != nil {
		setParts = append(setParts, fmt.Sprintf("odometer = $%d", argCounter))
		args = append(args, *req.Odometer)
		argCounter++
	}
	if req.ConditionStatus != nil {
		setParts = append(setParts, fmt.Sprintf("condition_status = $%d", argCounter))
		args = append(args, *req.ConditionStatus)
		argCounter++
	}
	if req.Status != nil {
		setParts = append(setParts, fmt.Sprintf("status = $%d", argCounter))
		args = append(args, *req.Status)
		argCounter++
	}
	if req.SellingPrice != nil {
		setParts = append(setParts, fmt.Sprintf("selling_price = $%d", argCounter))
		args = append(args, *req.SellingPrice)
		argCounter++
	}
	if req.Notes != nil {
		setParts = append(setParts, fmt.Sprintf("notes = $%d", argCounter))
		args = append(args, *req.Notes)
		argCounter++
	}

	// Add WHERE clause parameter
	args = append(args, id)

	query := fmt.Sprintf(`
		UPDATE vehicles 
		SET %s
		WHERE id = $%d
		RETURNING id, code, brand_id, model, year, color, engine_capacity, fuel_type,
				  transmission_type, license_plate, chassis_number, engine_number,
				  odometer, source_type, source_id, purchase_price, condition_status,
				  status, repair_cost, hpp_price, selling_price, sold_price, sold_date,
				  notes, created_by, created_at, updated_at`,
		strings.Join(setParts, ", "), argCounter)

	var vehicle models.Vehicle
	err := r.db.Get(&vehicle, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to update vehicle: %w", err)
	}

	return &vehicle, nil
}

func (r *vehicleRepository) Delete(id int) error {
	query := `DELETE FROM vehicles WHERE id = $1`
	
	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete vehicle: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("vehicle not found")
	}

	return nil
}

func (r *vehicleRepository) List(page, limit int, status *models.VehicleStatus) ([]models.Vehicle, int64, error) {
	offset := (page - 1) * limit

	// Build WHERE clause and count query
	var whereClause string
	var countArgs []interface{}
	var queryArgs []interface{}

	if status != nil {
		whereClause = "WHERE v.status = $1"
		countArgs = []interface{}{*status}
		queryArgs = []interface{}{*status, limit, offset}
	} else {
		whereClause = ""
		countArgs = []interface{}{}
		queryArgs = []interface{}{limit, offset}
	}

	// Get total count
	var total int64
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM vehicles v %s", whereClause)
	err := r.db.Get(&total, countQuery, countArgs...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count vehicles: %w", err)
	}

	// Build main query with proper parameter indexing
	var query string
	if status != nil {
		query = fmt.Sprintf(`
			SELECT 
				v.id, v.code, v.brand_id, v.model, v.year, v.color, v.engine_capacity,
				v.fuel_type, v.transmission_type, v.license_plate, v.chassis_number,
				v.engine_number, v.odometer, v.source_type, v.source_id, v.purchase_price,
				v.condition_status, v.status, v.repair_cost, v.hpp_price, v.selling_price,
				v.sold_price, v.sold_date, v.notes, v.created_by, v.created_at, v.updated_at,
				vb.id as "brand.id", vb.name as "brand.name", vb.type_id as "brand.type_id", vb.created_at as "brand.created_at"
			FROM vehicles v
			JOIN vehicle_brands vb ON v.brand_id = vb.id
			WHERE v.status = $1
			ORDER BY v.created_at DESC
			LIMIT $2 OFFSET $3`)
	} else {
		query = `
			SELECT 
				v.id, v.code, v.brand_id, v.model, v.year, v.color, v.engine_capacity,
				v.fuel_type, v.transmission_type, v.license_plate, v.chassis_number,
				v.engine_number, v.odometer, v.source_type, v.source_id, v.purchase_price,
				v.condition_status, v.status, v.repair_cost, v.hpp_price, v.selling_price,
				v.sold_price, v.sold_date, v.notes, v.created_by, v.created_at, v.updated_at,
				vb.id as "brand.id", vb.name as "brand.name", vb.type_id as "brand.type_id", vb.created_at as "brand.created_at"
			FROM vehicles v
			JOIN vehicle_brands vb ON v.brand_id = vb.id
			ORDER BY v.created_at DESC
			LIMIT $1 OFFSET $2`
	}

	var vehicles []models.Vehicle
	err = r.db.Select(&vehicles, query, queryArgs...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list vehicles: %w", err)
	}

	return vehicles, total, nil
}

func (r *vehicleRepository) GetAvailableVehicles(page, limit int) ([]models.Vehicle, int64, error) {
	status := models.VehicleStatusAvailable
	return r.List(page, limit, &status)
}

func (r *vehicleRepository) GetVehiclesInRepair(page, limit int) ([]models.Vehicle, int64, error) {
	status := models.VehicleStatusInRepair
	return r.List(page, limit, &status)
}

func (r *vehicleRepository) UpdateStatus(id int, status models.VehicleStatus) error {
	query := `UPDATE vehicles SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`
	
	result, err := r.db.Exec(query, status, id)
	if err != nil {
		return fmt.Errorf("failed to update vehicle status: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("vehicle not found")
	}

	return nil
}

func (r *vehicleRepository) UpdateHPPPrice(id int, hppPrice float64) error {
	query := `UPDATE vehicles SET hpp_price = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`
	
	result, err := r.db.Exec(query, hppPrice, id)
	if err != nil {
		return fmt.Errorf("failed to update vehicle HPP price: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("vehicle not found")
	}

	return nil
}

func (r *vehicleRepository) UpdateSellingPrice(id int, sellingPrice float64) error {
	query := `UPDATE vehicles SET selling_price = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`
	
	result, err := r.db.Exec(query, sellingPrice, id)
	if err != nil {
		return fmt.Errorf("failed to update vehicle selling price: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("vehicle not found")
	}

	return nil
}

func (r *vehicleRepository) UpdateRepairCost(id int, repairCost float64) error {
	query := `UPDATE vehicles SET repair_cost = $1, hpp_price = purchase_price + $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`
	
	result, err := r.db.Exec(query, repairCost, id)
	if err != nil {
		return fmt.Errorf("failed to update vehicle repair cost: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("vehicle not found")
	}

	return nil
}

func (r *vehicleRepository) MarkAsSold(id int, soldPrice float64) error {
	query := `
		UPDATE vehicles 
		SET status = 'sold', sold_price = $1, sold_date = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP 
		WHERE id = $2`
	
	result, err := r.db.Exec(query, soldPrice, id)
	if err != nil {
		return fmt.Errorf("failed to mark vehicle as sold: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("vehicle not found")
	}

	return nil
}