package repository

import (
	"database/sql"
	"fmt"
	"log"
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
	SearchVehicles(offset, limit int, filters models.VehicleSearchFilters) ([]models.Vehicle, int64, error)
	GetAllBrands() ([]models.VehicleBrand, error)
}

type vehicleRepository struct {
	db *database.Database
}

func NewVehicleRepository(db *database.Database) VehicleRepository {
	return &vehicleRepository{db: db}
}

func (r *vehicleRepository) Create(req *models.VehicleCreateRequest, createdBy int) (*models.Vehicle, error) {
	log.Printf("VehicleRepository.Create - Request: %+v, CreatedBy: %d", req, createdBy)

	// Retry mechanism for sequence conflicts
	maxRetries := 3
	for attempt := 0; attempt < maxRetries; attempt++ {
		vehicle, err := r.attemptCreate(req, createdBy)
		if err == nil {
			log.Printf("VehicleRepository.Create - Success: %+v", vehicle)
			return vehicle, nil
		}

		// Check if it's a primary key violation
		if strings.Contains(err.Error(), "duplicate key value violates unique constraint \"vehicles_pkey\"") {
			log.Printf("VehicleRepository.Create - Primary key conflict on attempt %d, fixing sequence...", attempt+1)
			r.fixSequence()
			continue
		}

		// For other errors, return immediately
		log.Printf("VehicleRepository.Create - Error: %v", err)
		return nil, fmt.Errorf("failed to create vehicle: %w", err)
	}

	return nil, fmt.Errorf("failed to create vehicle after %d attempts: sequence conflicts", maxRetries)
}

func (r *vehicleRepository) attemptCreate(req *models.VehicleCreateRequest, createdBy int) (*models.Vehicle, error) {
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

	return &vehicle, err
}

func (r *vehicleRepository) fixSequence() {
	query := `SELECT setval('vehicles_id_seq', (SELECT COALESCE(MAX(id), 0) FROM vehicles) + 1);`
	_, err := r.db.Exec(query)
	if err != nil {
		log.Printf("VehicleRepository.fixSequence - Error: %v", err)
	} else {
		log.Printf("VehicleRepository.fixSequence - Sequence fixed successfully")
	}
}

func (r *vehicleRepository) GetByID(id int) (*models.Vehicle, error) {
	// First get the vehicle basic info
	query := `
		SELECT 
			id, code, brand_id, model, year, color, engine_capacity,
			fuel_type, transmission_type, license_plate, chassis_number,
			engine_number, odometer, source_type, source_id, purchase_price,
			condition_status, status, repair_cost, hpp_price, selling_price,
			sold_price, sold_date, notes, created_by, created_at, updated_at
		FROM vehicles
		WHERE id = $1`

	var vehicle models.Vehicle
	err := r.db.Get(&vehicle, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("vehicle not found")
		}
		return nil, fmt.Errorf("failed to get vehicle: %w", err)
	}

	// Then get the brand info
	brandQuery := `
		SELECT 
			vb.id, vb.name, vb.type_id, vb.created_at
		FROM vehicle_brands vb
		WHERE vb.id = $1`

	var brand models.VehicleBrand
	err = r.db.Get(&brand, brandQuery, vehicle.BrandID)
	if err != nil && err != sql.ErrNoRows {
		return nil, fmt.Errorf("failed to get vehicle brand: %w", err)
	}

	if err != sql.ErrNoRows {
		vehicle.Brand = &brand
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

func (r *vehicleRepository) SearchVehicles(offset, limit int, filters models.VehicleSearchFilters) ([]models.Vehicle, int64, error) {
	// Build the base query with proper JOINs
	baseQuery := `
		FROM vehicles v
		LEFT JOIN vehicle_brands vb ON v.brand_id = vb.id
		WHERE v.deleted_at IS NULL
	`

	var args []interface{}
	var whereConditions []string
	argIndex := 1

	// Build WHERE conditions based on filters
	if filters.BrandID != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("v.brand_id = $%d", argIndex))
		args = append(args, *filters.BrandID)
		argIndex++
	}

	if filters.Model != "" {
		whereConditions = append(whereConditions, fmt.Sprintf("LOWER(v.model) LIKE LOWER($%d)", argIndex))
		args = append(args, "%"+filters.Model+"%")
		argIndex++
	}

	if filters.YearMin != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("v.year >= $%d", argIndex))
		args = append(args, *filters.YearMin)
		argIndex++
	}

	if filters.YearMax != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("v.year <= $%d", argIndex))
		args = append(args, *filters.YearMax)
		argIndex++
	}

	if filters.Color != "" {
		whereConditions = append(whereConditions, fmt.Sprintf("LOWER(v.color) LIKE LOWER($%d)", argIndex))
		args = append(args, "%"+filters.Color+"%")
		argIndex++
	}

	if filters.OdometerMin != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("v.odometer >= $%d", argIndex))
		args = append(args, *filters.OdometerMin)
		argIndex++
	}

	if filters.OdometerMax != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("v.odometer <= $%d", argIndex))
		args = append(args, *filters.OdometerMax)
		argIndex++
	}

	if filters.PriceMin != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("v.selling_price >= $%d", argIndex))
		args = append(args, *filters.PriceMin)
		argIndex++
	}

	if filters.PriceMax != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("v.selling_price <= $%d", argIndex))
		args = append(args, *filters.PriceMax)
		argIndex++
	}

	if filters.Status != "" {
		whereConditions = append(whereConditions, fmt.Sprintf("LOWER(v.status) = LOWER($%d)", argIndex))
		args = append(args, filters.Status)
		argIndex++
	}

	// Add additional WHERE conditions
	if len(whereConditions) > 0 {
		baseQuery += " AND " + strings.Join(whereConditions, " AND ")
	}

	// Count total records
	countQuery := "SELECT COUNT(*) " + baseQuery
	var totalCount int64
	err := r.db.QueryRow(countQuery, args...).Scan(&totalCount)
	if err != nil {
		return nil, 0, err
	}

	// Get paginated results
	query := fmt.Sprintf(`
		SELECT v.id, v.code, v.brand_id, vb.name as brand_name, 
			   v.model, v.year, v.color, v.engine_capacity, v.fuel_type,
			   v.transmission_type, v.license_plate, v.chassis_number, v.engine_number,
			   v.odometer, v.source_type, v.source_id, v.purchase_price,
			   v.condition_status, v.status, v.repair_cost, v.hpp_price, 
			   v.selling_price, v.sold_price, v.sold_date, v.notes,
			   v.created_by, v.created_at, v.updated_at
		%s
		ORDER BY v.created_at DESC
		LIMIT $%d OFFSET $%d
	`, baseQuery, argIndex, argIndex+1)

	args = append(args, limit, offset)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var vehicles []models.Vehicle
	for rows.Next() {
		var v models.Vehicle
		var brandName sql.NullString
		err := rows.Scan(
			&v.ID, &v.Code, &v.BrandID, &brandName,
			&v.Model, &v.Year, &v.Color, &v.EngineCapacity, &v.FuelType,
			&v.TransmissionType, &v.LicensePlate, &v.ChassisNumber, &v.EngineNumber,
			&v.Odometer, &v.SourceType, &v.SourceID, &v.PurchasePrice,
			&v.ConditionStatus, &v.Status, &v.RepairCost, &v.HPPPrice,
			&v.SellingPrice, &v.SoldPrice, &v.SoldDate, &v.Notes,
			&v.CreatedBy, &v.CreatedAt, &v.UpdatedAt,
		)
		if err != nil {
			return nil, 0, err
		}

		// Create Brand object if brand name exists
		if brandName.Valid {
			v.Brand = &models.VehicleBrand{
				ID:   v.BrandID,
				Name: brandName.String,
			}
		}

		vehicles = append(vehicles, v)
	}

	if err = rows.Err(); err != nil {
		return nil, 0, err
	}

	return vehicles, totalCount, nil
}

func (r *vehicleRepository) GetAllBrands() ([]models.VehicleBrand, error) {
	query := `
		SELECT id, name
		FROM vehicle_brands
		ORDER BY name ASC
	`

	rows, err := r.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var brands []models.VehicleBrand
	for rows.Next() {
		var brand models.VehicleBrand
		err := rows.Scan(&brand.ID, &brand.Name)
		if err != nil {
			return nil, err
		}
		brands = append(brands, brand)
	}

	return brands, nil
}
