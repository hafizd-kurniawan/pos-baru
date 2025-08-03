package repository

import (
	"database/sql"
	"fmt"
	"strings"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/jmoiron/sqlx"
)

type VehicleBrandRepository interface {
	Create(req *models.VehicleBrandCreateRequest) (*models.VehicleBrand, error)
	GetByID(id int) (*models.VehicleBrand, error)
	Update(id int, req *models.VehicleBrandUpdateRequest) (*models.VehicleBrand, error)
	Delete(id int) error
	List(page, limit int) ([]models.VehicleBrand, int64, error)
	GetByTypeID(typeID int) ([]models.VehicleBrand, error)
}

type vehicleBrandRepository struct {
	db *sqlx.DB
}

func NewVehicleBrandRepository(db *sqlx.DB) VehicleBrandRepository {
	return &vehicleBrandRepository{
		db: db,
	}
}

func (r *vehicleBrandRepository) Create(req *models.VehicleBrandCreateRequest) (*models.VehicleBrand, error) {
	query := `
		INSERT INTO vehicle_brands (name, type_id)
		VALUES ($1, $2)
		RETURNING id, name, type_id, created_at`

	var brand models.VehicleBrand
	err := r.db.Get(&brand, query, req.Name, req.TypeID)
	if err != nil {
		return nil, fmt.Errorf("failed to create vehicle brand: %w", err)
	}

	return &brand, nil
}

func (r *vehicleBrandRepository) GetByID(id int) (*models.VehicleBrand, error) {
	query := `
		SELECT 
			vb.id, vb.name, vb.type_id, vb.created_at,
			vt.id as "vehicle_type.id", vt.name as "vehicle_type.name", 
			vt.description as "vehicle_type.description", vt.created_at as "vehicle_type.created_at"
		FROM vehicle_brands vb
		LEFT JOIN vehicle_types vt ON vb.type_id = vt.id
		WHERE vb.id = $1`

	var brand models.VehicleBrand
	err := r.db.Get(&brand, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("vehicle brand not found")
		}
		return nil, fmt.Errorf("failed to get vehicle brand: %w", err)
	}

	return &brand, nil
}

func (r *vehicleBrandRepository) Update(id int, req *models.VehicleBrandUpdateRequest) (*models.VehicleBrand, error) {
	// Build dynamic update query
	setParts := []string{}
	args := []interface{}{}
	argCounter := 1

	if req.Name != nil {
		setParts = append(setParts, fmt.Sprintf("name = $%d", argCounter))
		args = append(args, *req.Name)
		argCounter++
	}
	if req.TypeID != nil {
		setParts = append(setParts, fmt.Sprintf("type_id = $%d", argCounter))
		args = append(args, *req.TypeID)
		argCounter++
	}

	if len(setParts) == 0 {
		return nil, fmt.Errorf("no fields to update")
	}

	// Add WHERE clause parameter
	args = append(args, id)

	query := fmt.Sprintf(`
		UPDATE vehicle_brands 
		SET %s
		WHERE id = $%d
		RETURNING id, name, type_id, created_at`,
		strings.Join(setParts, ", "), argCounter)

	var brand models.VehicleBrand
	err := r.db.Get(&brand, query, args...)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("vehicle brand not found")
		}
		return nil, fmt.Errorf("failed to update vehicle brand: %w", err)
	}

	return &brand, nil
}

func (r *vehicleBrandRepository) Delete(id int) error {
	query := `DELETE FROM vehicle_brands WHERE id = $1`

	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete vehicle brand: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("vehicle brand not found")
	}

	return nil
}

func (r *vehicleBrandRepository) List(page, limit int) ([]models.VehicleBrand, int64, error) {
	offset := (page - 1) * limit

	query := `
		SELECT 
			vb.id, vb.name, vb.type_id, vb.created_at,
			vt.id as "vehicle_type.id", vt.name as "vehicle_type.name", 
			vt.description as "vehicle_type.description", vt.created_at as "vehicle_type.created_at"
		FROM vehicle_brands vb
		LEFT JOIN vehicle_types vt ON vb.type_id = vt.id
		ORDER BY vb.name
		LIMIT $1 OFFSET $2`

	var brands []models.VehicleBrand
	err := r.db.Select(&brands, query, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get vehicle brands: %w", err)
	}

	// Get total count
	countQuery := `SELECT COUNT(*) FROM vehicle_brands`
	var total int64
	err = r.db.Get(&total, countQuery)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get vehicle brands count: %w", err)
	}

	return brands, total, nil
}

func (r *vehicleBrandRepository) GetByTypeID(typeID int) ([]models.VehicleBrand, error) {
	query := `
		SELECT 
			vb.id, vb.name, vb.type_id, vb.created_at,
			vt.id as "vehicle_type.id", vt.name as "vehicle_type.name", 
			vt.description as "vehicle_type.description", vt.created_at as "vehicle_type.created_at"
		FROM vehicle_brands vb
		LEFT JOIN vehicle_types vt ON vb.type_id = vt.id
		WHERE vb.type_id = $1
		ORDER BY vb.name`

	var brands []models.VehicleBrand
	err := r.db.Select(&brands, query, typeID)
	if err != nil {
		return nil, fmt.Errorf("failed to get vehicle brands by type: %w", err)
	}

	return brands, nil
}
