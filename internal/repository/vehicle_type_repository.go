package repository

import (
	"database/sql"
	"fmt"
	"strings"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/pkg/database"
)

type VehicleTypeRepository interface {
	Create(req *models.VehicleTypeCreateRequest) (*models.VehicleType, error)
	GetByID(id int) (*models.VehicleType, error)
	GetByName(name string) (*models.VehicleType, error)
	Update(id int, req *models.VehicleTypeUpdateRequest) (*models.VehicleType, error)
	Delete(id int) error
	List() ([]models.VehicleType, error)
}

type vehicleTypeRepository struct {
	db *database.Database
}

func NewVehicleTypeRepository(db *database.Database) VehicleTypeRepository {
	return &vehicleTypeRepository{db: db}
}

func (r *vehicleTypeRepository) Create(req *models.VehicleTypeCreateRequest) (*models.VehicleType, error) {
	query := `
		INSERT INTO vehicle_types (name, description)
		VALUES ($1, $2)
		RETURNING id, name, description, created_at`

	var vehicleType models.VehicleType
	err := r.db.Get(&vehicleType, query, req.Name, req.Description)
	if err != nil {
		return nil, fmt.Errorf("failed to create vehicle type: %w", err)
	}

	return &vehicleType, nil
}

func (r *vehicleTypeRepository) GetByID(id int) (*models.VehicleType, error) {
	query := `
		SELECT id, name, description, created_at
		FROM vehicle_types
		WHERE id = $1`

	var vehicleType models.VehicleType
	err := r.db.Get(&vehicleType, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("vehicle type not found")
		}
		return nil, fmt.Errorf("failed to get vehicle type: %w", err)
	}

	return &vehicleType, nil
}

func (r *vehicleTypeRepository) GetByName(name string) (*models.VehicleType, error) {
	query := `
		SELECT id, name, description, created_at
		FROM vehicle_types
		WHERE name = $1`

	var vehicleType models.VehicleType
	err := r.db.Get(&vehicleType, query, name)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("vehicle type not found")
		}
		return nil, fmt.Errorf("failed to get vehicle type: %w", err)
	}

	return &vehicleType, nil
}

func (r *vehicleTypeRepository) Update(id int, req *models.VehicleTypeUpdateRequest) (*models.VehicleType, error) {
	// Build dynamic update query
	setParts := []string{}
	args := []interface{}{}
	argCounter := 1

	if req.Name != nil {
		setParts = append(setParts, fmt.Sprintf("name = $%d", argCounter))
		args = append(args, *req.Name)
		argCounter++
	}
	if req.Description != nil {
		setParts = append(setParts, fmt.Sprintf("description = $%d", argCounter))
		args = append(args, *req.Description)
		argCounter++
	}

	if len(setParts) == 0 {
		return nil, fmt.Errorf("no fields to update")
	}

	// Add WHERE clause parameter
	args = append(args, id)

	query := fmt.Sprintf(`
		UPDATE vehicle_types 
		SET %s
		WHERE id = $%d
		RETURNING id, name, description, created_at`,
		strings.Join(setParts, ", "), argCounter)

	var vehicleType models.VehicleType
	err := r.db.Get(&vehicleType, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to update vehicle type: %w", err)
	}

	return &vehicleType, nil
}

func (r *vehicleTypeRepository) Delete(id int) error {
	query := `DELETE FROM vehicle_types WHERE id = $1`

	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete vehicle type: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("vehicle type not found")
	}

	return nil
}

func (r *vehicleTypeRepository) List() ([]models.VehicleType, error) {
	query := `
		SELECT id, name, description, created_at
		FROM vehicle_types
		ORDER BY name ASC`

	var vehicleTypes []models.VehicleType
	err := r.db.Select(&vehicleTypes, query)
	if err != nil {
		return nil, fmt.Errorf("failed to list vehicle types: %w", err)
	}

	return vehicleTypes, nil
}
