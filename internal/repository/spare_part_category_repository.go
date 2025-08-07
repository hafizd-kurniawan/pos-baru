package repository

import (
	"database/sql"
	"fmt"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
)

type SparePartCategoryRepository interface {
	Create(req *models.SparePartCategoryCreateRequest) (*models.SparePartCategory, error)
	GetByID(id int) (*models.SparePartCategory, error)
	Update(id int, req *models.SparePartCategoryUpdateRequest) (*models.SparePartCategory, error)
	Delete(id int) error
	List(page, limit int, isActive *bool) ([]models.SparePartCategory, int64, error)
}

type sparePartCategoryRepository struct {
	db *sql.DB
}

func NewSparePartCategoryRepository(db *sql.DB) SparePartCategoryRepository {
	return &sparePartCategoryRepository{
		db: db,
	}
}

func (r *sparePartCategoryRepository) Create(req *models.SparePartCategoryCreateRequest) (*models.SparePartCategory, error) {
	query := `
		INSERT INTO spare_part_categories (name, description, is_active)
		VALUES ($1, $2, $3)
		RETURNING id, name, description, is_active, created_at, updated_at
	`

	var category models.SparePartCategory
	err := r.db.QueryRow(query, req.Name, req.Description, req.IsActive).Scan(
		&category.ID,
		&category.Name,
		&category.Description,
		&category.IsActive,
		&category.CreatedAt,
		&category.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create spare part category: %w", err)
	}

	return &category, nil
}

func (r *sparePartCategoryRepository) GetByID(id int) (*models.SparePartCategory, error) {
	query := `
		SELECT id, name, description, is_active, created_at, updated_at
		FROM spare_part_categories
		WHERE id = $1
	`

	var category models.SparePartCategory
	err := r.db.QueryRow(query, id).Scan(
		&category.ID,
		&category.Name,
		&category.Description,
		&category.IsActive,
		&category.CreatedAt,
		&category.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("spare part category not found")
		}
		return nil, fmt.Errorf("failed to get spare part category: %w", err)
	}

	return &category, nil
}

func (r *sparePartCategoryRepository) Update(id int, req *models.SparePartCategoryUpdateRequest) (*models.SparePartCategory, error) {
	setParts := make([]string, 0)
	args := make([]interface{}, 0)
	argIndex := 1

	if req.Name != nil {
		setParts = append(setParts, fmt.Sprintf("name = $%d", argIndex))
		args = append(args, *req.Name)
		argIndex++
	}

	if req.Description != nil {
		setParts = append(setParts, fmt.Sprintf("description = $%d", argIndex))
		args = append(args, *req.Description)
		argIndex++
	}

	if req.IsActive != nil {
		setParts = append(setParts, fmt.Sprintf("is_active = $%d", argIndex))
		args = append(args, *req.IsActive)
		argIndex++
	}

	if len(setParts) == 0 {
		return nil, fmt.Errorf("no fields to update")
	}

	setParts = append(setParts, fmt.Sprintf("updated_at = NOW()"))
	args = append(args, id)

	query := fmt.Sprintf(`
		UPDATE spare_part_categories
		SET %s
		WHERE id = $%d
		RETURNING id, name, description, is_active, created_at, updated_at
	`, fmt.Sprintf("%s", setParts), argIndex)

	var category models.SparePartCategory
	err := r.db.QueryRow(query, args...).Scan(
		&category.ID,
		&category.Name,
		&category.Description,
		&category.IsActive,
		&category.CreatedAt,
		&category.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("spare part category not found")
		}
		return nil, fmt.Errorf("failed to update spare part category: %w", err)
	}

	return &category, nil
}

func (r *sparePartCategoryRepository) Delete(id int) error {
	query := `DELETE FROM spare_part_categories WHERE id = $1`

	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete spare part category: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check affected rows: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("spare part category not found")
	}

	return nil
}

func (r *sparePartCategoryRepository) List(page, limit int, isActive *bool) ([]models.SparePartCategory, int64, error) {
	// Count query
	countQuery := `SELECT COUNT(*) FROM spare_part_categories`
	countArgs := make([]interface{}, 0)

	if isActive != nil {
		countQuery += ` WHERE is_active = $1`
		countArgs = append(countArgs, *isActive)
	}

	var total int64
	err := r.db.QueryRow(countQuery, countArgs...).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count spare part categories: %w", err)
	}

	// Data query
	dataQuery := `
		SELECT id, name, description, is_active, created_at, updated_at
		FROM spare_part_categories
	`
	dataArgs := make([]interface{}, 0)

	if isActive != nil {
		dataQuery += ` WHERE is_active = $1`
		dataArgs = append(dataArgs, *isActive)
	}

	dataQuery += ` ORDER BY created_at DESC LIMIT $%d OFFSET $%d`
	dataArgs = append(dataArgs, limit, (page-1)*limit)

	rows, err := r.db.Query(dataQuery, dataArgs...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list spare part categories: %w", err)
	}
	defer rows.Close()

	categories := make([]models.SparePartCategory, 0)
	for rows.Next() {
		var category models.SparePartCategory
		err := rows.Scan(
			&category.ID,
			&category.Name,
			&category.Description,
			&category.IsActive,
			&category.CreatedAt,
			&category.UpdatedAt,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan spare part category: %w", err)
		}
		categories = append(categories, category)
	}

	return categories, total, nil
}
