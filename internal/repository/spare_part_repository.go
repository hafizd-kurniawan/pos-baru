package repository

import (
	"database/sql"
	"fmt"
	"strings"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/pkg/database"
)

type SparePartRepository interface {
	Create(req *models.SparePartCreateRequest) (*models.SparePart, error)
	GetByID(id int) (*models.SparePart, error)
	GetByCode(code string) (*models.SparePart, error)
	Update(id int, req *models.SparePartUpdateRequest) (*models.SparePart, error)
	Delete(id int) error
	List(page, limit int, isActive *bool) ([]models.SparePart, int64, error)
	ListWithFilters(page, limit int, search, category string, isActive *bool) ([]models.SparePart, int64, error)
	UpdateStock(id int, quantity int, operation string) error
	GetLowStockItems(page, limit int) ([]models.SparePart, int64, error)
	CheckStockAvailability(id int, requestedQuantity int) (bool, error)
	BulkUpdateStock(updates []models.SparePartStockUpdate) error
	GetCategories() ([]string, error)
	// Category management methods
	GetCategoriesWithPagination(page, limit int, search string) ([]models.CategoryInfo, int64, error)
	CreateCategory(name, description string) error
	UpdateCategory(id int, name, description string) error
	DeleteCategory(id int) error
	GetCategoryStats() ([]models.CategoryStats, error)
}

type sparePartRepository struct {
	db *database.Database
}

func NewSparePartRepository(db *database.Database) SparePartRepository {
	return &sparePartRepository{db: db}
}

func (r *sparePartRepository) Create(req *models.SparePartCreateRequest) (*models.SparePart, error) {
	query := `
		INSERT INTO spare_parts (code, name, description, category, unit, purchase_price, selling_price, stock_quantity, minimum_stock)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING id, code, name, description, category, unit, purchase_price, selling_price, stock_quantity, minimum_stock, is_active, created_at, updated_at`

	var sparePart models.SparePart
	err := r.db.Get(&sparePart, query, req.Code, req.Name, req.Description, req.Category, req.Unit, req.PurchasePrice, req.SellingPrice, req.StockQuantity, req.MinimumStock)
	if err != nil {
		return nil, fmt.Errorf("failed to create spare part: %w", err)
	}

	return &sparePart, nil
}

func (r *sparePartRepository) GetByID(id int) (*models.SparePart, error) {
	query := `
		SELECT id, code, name, description, category, unit, purchase_price, selling_price, stock_quantity, minimum_stock, is_active, created_at, updated_at
		FROM spare_parts 
		WHERE id = $1`

	var sparePart models.SparePart
	err := r.db.Get(&sparePart, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("spare part not found")
		}
		return nil, fmt.Errorf("failed to get spare part: %w", err)
	}

	return &sparePart, nil
}

func (r *sparePartRepository) GetByCode(code string) (*models.SparePart, error) {
	query := `
		SELECT id, code, name, description, category, unit, purchase_price, selling_price, stock_quantity, minimum_stock, is_active, created_at, updated_at
		FROM spare_parts 
		WHERE code = $1`

	var sparePart models.SparePart
	err := r.db.Get(&sparePart, query, code)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("spare part not found")
		}
		return nil, fmt.Errorf("failed to get spare part: %w", err)
	}

	return &sparePart, nil
}

func (r *sparePartRepository) Update(id int, req *models.SparePartUpdateRequest) (*models.SparePart, error) {
	// Build dynamic update query
	setParts := []string{"updated_at = CURRENT_TIMESTAMP"}
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
	if req.Category != nil {
		setParts = append(setParts, fmt.Sprintf("category = $%d", argCounter))
		args = append(args, *req.Category)
		argCounter++
	}
	if req.Unit != nil {
		setParts = append(setParts, fmt.Sprintf("unit = $%d", argCounter))
		args = append(args, *req.Unit)
		argCounter++
	}
	if req.PurchasePrice != nil {
		setParts = append(setParts, fmt.Sprintf("purchase_price = $%d", argCounter))
		args = append(args, *req.PurchasePrice)
		argCounter++
	}
	if req.SellingPrice != nil {
		setParts = append(setParts, fmt.Sprintf("selling_price = $%d", argCounter))
		args = append(args, *req.SellingPrice)
		argCounter++
	}
	if req.StockQuantity != nil {
		setParts = append(setParts, fmt.Sprintf("stock_quantity = $%d", argCounter))
		args = append(args, *req.StockQuantity)
		argCounter++
	}
	if req.MinimumStock != nil {
		setParts = append(setParts, fmt.Sprintf("minimum_stock = $%d", argCounter))
		args = append(args, *req.MinimumStock)
		argCounter++
	}
	if req.IsActive != nil {
		setParts = append(setParts, fmt.Sprintf("is_active = $%d", argCounter))
		args = append(args, *req.IsActive)
		argCounter++
	}

	// Add WHERE clause parameter
	args = append(args, id)

	query := fmt.Sprintf(`
		UPDATE spare_parts 
		SET %s
		WHERE id = $%d
		RETURNING id, code, name, description, category, unit, purchase_price, selling_price, stock_quantity, minimum_stock, is_active, created_at, updated_at`,
		strings.Join(setParts, ", "), argCounter)

	var sparePart models.SparePart
	err := r.db.Get(&sparePart, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to update spare part: %w", err)
	}

	return &sparePart, nil
}

func (r *sparePartRepository) Delete(id int) error {
	query := `DELETE FROM spare_parts WHERE id = $1`

	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete spare part: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("spare part not found")
	}

	return nil
}

func (r *sparePartRepository) List(page, limit int, isActive *bool) ([]models.SparePart, int64, error) {
	offset := (page - 1) * limit

	// Build WHERE clause
	whereClause := ""
	args := []interface{}{limit, offset}
	if isActive != nil {
		whereClause = "WHERE is_active = $3"
		args = []interface{}{limit, offset, *isActive}
	}

	// Get total count
	var total int64
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM spare_parts %s", whereClause)
	if isActive != nil {
		err := r.db.Get(&total, countQuery, *isActive)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to count spare parts: %w", err)
		}
	} else {
		err := r.db.Get(&total, countQuery)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to count spare parts: %w", err)
		}
	}

	// Get spare parts with pagination
	query := fmt.Sprintf(`
		SELECT id, code, name, description, category, unit, purchase_price, selling_price, stock_quantity, minimum_stock, is_active, created_at, updated_at
		FROM spare_parts
		%s
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2`, whereClause)

	var spareParts []models.SparePart
	err := r.db.Select(&spareParts, query, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list spare parts: %w", err)
	}

	return spareParts, total, nil
}

func (r *sparePartRepository) UpdateStock(id int, quantity int, operation string) error {
	var query string
	if operation == "add" {
		query = `UPDATE spare_parts SET stock_quantity = stock_quantity + $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`
	} else if operation == "subtract" {
		query = `UPDATE spare_parts SET stock_quantity = stock_quantity - $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 AND stock_quantity >= $1`
	} else {
		return fmt.Errorf("invalid operation: %s", operation)
	}

	result, err := r.db.Exec(query, quantity, id)
	if err != nil {
		return fmt.Errorf("failed to update spare part stock: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		if operation == "subtract" {
			return fmt.Errorf("insufficient stock or spare part not found")
		}
		return fmt.Errorf("spare part not found")
	}

	return nil
}

func (r *sparePartRepository) GetLowStockItems(page, limit int) ([]models.SparePart, int64, error) {
	offset := (page - 1) * limit

	// Get total count
	var total int64
	countQuery := `SELECT COUNT(*) FROM spare_parts WHERE stock_quantity <= minimum_stock AND is_active = true`
	err := r.db.Get(&total, countQuery)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count low stock items: %w", err)
	}

	// Get low stock items with pagination
	query := `
		SELECT id, code, name, description, category, unit, purchase_price, selling_price, stock_quantity, minimum_stock, is_active, created_at, updated_at
		FROM spare_parts
		WHERE stock_quantity <= minimum_stock AND is_active = true
		ORDER BY (stock_quantity - minimum_stock) ASC, created_at DESC
		LIMIT $1 OFFSET $2`

	var spareParts []models.SparePart
	err = r.db.Select(&spareParts, query, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get low stock items: %w", err)
	}

	return spareParts, total, nil
}

func (r *sparePartRepository) CheckStockAvailability(id int, requestedQuantity int) (bool, error) {
	query := `SELECT stock_quantity FROM spare_parts WHERE id = $1 AND is_active = true`

	var currentStock int
	err := r.db.Get(&currentStock, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return false, fmt.Errorf("spare part not found or inactive")
		}
		return false, fmt.Errorf("failed to check stock availability: %w", err)
	}

	return currentStock >= requestedQuantity, nil
}

func (r *sparePartRepository) BulkUpdateStock(updates []models.SparePartStockUpdate) error {
	tx, err := r.db.Beginx()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	for _, update := range updates {
		var query string
		if update.Operation == "add" {
			query = `UPDATE spare_parts SET stock_quantity = stock_quantity + $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`
		} else if update.Operation == "subtract" {
			query = `UPDATE spare_parts SET stock_quantity = stock_quantity - $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 AND stock_quantity >= $1`
		} else {
			return fmt.Errorf("invalid operation: %s", update.Operation)
		}

		result, err := tx.Exec(query, update.Quantity)
		if err != nil {
			return fmt.Errorf("failed to update stock: %w", err)
		}

		rowsAffected, err := result.RowsAffected()
		if err != nil {
			return fmt.Errorf("failed to get rows affected: %w", err)
		}

		if rowsAffected == 0 {
			if update.Operation == "subtract" {
				return fmt.Errorf("insufficient stock for spare part")
			}
			return fmt.Errorf("spare part not found")
		}
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// GetCategories retrieves unique categories from spare parts
func (r *sparePartRepository) GetCategories() ([]string, error) {
	query := `
		SELECT name 
		FROM spare_part_categories 
		WHERE is_active = true
		ORDER BY name`

	var categories []string
	err := r.db.Select(&categories, query)
	if err != nil {
		return nil, fmt.Errorf("failed to get categories: %w", err)
	}

	return categories, nil
}

func (r *sparePartRepository) ListWithFilters(page, limit int, search, category string, isActive *bool) ([]models.SparePart, int64, error) {
	offset := (page - 1) * limit

	// Build WHERE clause dynamically
	conditions := []string{}
	args := []interface{}{}
	paramCount := 1

	if isActive != nil {
		conditions = append(conditions, fmt.Sprintf("is_active = $%d", paramCount))
		args = append(args, *isActive)
		paramCount++
	}

	if search != "" {
		conditions = append(conditions, fmt.Sprintf("(name ILIKE $%d OR code ILIKE $%d OR category ILIKE $%d)", paramCount, paramCount+1, paramCount+2))
		searchPattern := "%" + search + "%"
		args = append(args, searchPattern, searchPattern, searchPattern)
		paramCount += 3
	}

	if category != "" {
		conditions = append(conditions, fmt.Sprintf("category ILIKE $%d", paramCount))
		args = append(args, category)
		paramCount++
	}

	var whereClause string
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	// Get total count
	var total int64
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM spare_parts %s", whereClause)
	err := r.db.Get(&total, countQuery, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count spare parts: %w", err)
	}

	// Add pagination parameters
	args = append(args, limit, offset)

	// Get spare parts with filtering and pagination
	query := fmt.Sprintf(`
		SELECT id, code, name, description, category, unit, purchase_price, selling_price, stock_quantity, minimum_stock, is_active, created_at, updated_at
		FROM spare_parts
		%s
		ORDER BY created_at DESC
		LIMIT $%d OFFSET $%d`, whereClause, paramCount, paramCount+1)

	var spareParts []models.SparePart
	err = r.db.Select(&spareParts, query, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list spare parts: %w", err)
	}

	return spareParts, total, nil
}

// Category management implementations

func (r *sparePartRepository) GetCategoriesWithPagination(page, limit int, search string) ([]models.CategoryInfo, int64, error) {
	offset := (page - 1) * limit

	// Get total count of active categories
	var total int64
	countQuery := `SELECT COUNT(*) FROM spare_part_categories WHERE is_active = true`
	countArgs := []interface{}{}

	if search != "" {
		countQuery += " AND name ILIKE $1"
		countArgs = append(countArgs, "%"+search+"%")
	}

	err := r.db.Get(&total, countQuery, countArgs...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count categories: %w", err)
	}

	// Get categories with spare parts count
	query := `
		SELECT 
			c.id,
			c.name,
			COALESCE(c.description, '') as description,
			COALESCE(COUNT(sp.id), 0) as spare_part_count,
			c.is_active,
			c.created_at,
			c.updated_at
		FROM spare_part_categories c
		LEFT JOIN spare_parts sp ON c.name = sp.category
		WHERE c.is_active = true
	`
	queryArgs := []interface{}{}

	if search != "" {
		query += " AND c.name ILIKE $1"
		queryArgs = append(queryArgs, "%"+search+"%")
	}

	query += " GROUP BY c.id, c.name, c.description, c.is_active, c.created_at, c.updated_at"
	query += " ORDER BY c.created_at DESC"
	query += " LIMIT $" + fmt.Sprintf("%d", len(queryArgs)+1) + " OFFSET $" + fmt.Sprintf("%d", len(queryArgs)+2)
	queryArgs = append(queryArgs, limit, offset)

	var categories []models.CategoryInfo
	err = r.db.Select(&categories, query, queryArgs...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get categories: %w", err)
	}

	return categories, total, nil
}

func (r *sparePartRepository) CreateCategory(name, description string) error {
	// Check if category already exists
	var count int
	err := r.db.Get(&count, "SELECT COUNT(*) FROM spare_part_categories WHERE name = $1 AND is_active = true", name)
	if err != nil {
		return fmt.Errorf("failed to check category existence: %w", err)
	}

	if count > 0 {
		return fmt.Errorf("category '%s' already exists", name)
	}

	// Insert into spare_part_categories table
	query := `
		INSERT INTO spare_part_categories (name, description, is_active, created_at, updated_at) 
		VALUES ($1, $2, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
	`

	_, err = r.db.Exec(query, name, description)
	if err != nil {
		return fmt.Errorf("failed to create category: %v", err)
	}

	return nil
}

func (r *sparePartRepository) UpdateCategory(id int, name, description string) error {
	// Check if new name already exists (except for current category)
	var count int
	err := r.db.Get(&count, "SELECT COUNT(*) FROM spare_part_categories WHERE name = $1 AND id != $2 AND is_active = true", name, id)
	if err != nil {
		return fmt.Errorf("failed to check category name uniqueness: %w", err)
	}

	if count > 0 {
		return fmt.Errorf("category name '%s' already exists", name)
	}

	// Get the old category name first
	var oldCategory string
	err = r.db.Get(&oldCategory, "SELECT name FROM spare_part_categories WHERE id = $1 AND is_active = true", id)
	if err != nil {
		return fmt.Errorf("category not found: %w", err)
	}

	// Update the category in spare_part_categories table
	_, err = r.db.Exec(`
		UPDATE spare_part_categories 
		SET name = $1, description = $2, updated_at = CURRENT_TIMESTAMP 
		WHERE id = $3 AND is_active = true
	`, name, description, id)
	if err != nil {
		return fmt.Errorf("failed to update category: %w", err)
	}

	// Update all spare parts that use this category
	_, err = r.db.Exec(`
		UPDATE spare_parts 
		SET category = $1, updated_at = CURRENT_TIMESTAMP 
		WHERE category = $2
	`, name, oldCategory)
	if err != nil {
		return fmt.Errorf("failed to update spare parts category reference: %w", err)
	}

	return nil
}

func (r *sparePartRepository) DeleteCategory(id int) error {
	// Get the category name first
	var categoryName string
	err := r.db.Get(&categoryName, "SELECT name FROM spare_part_categories WHERE id = $1 AND is_active = true", id)
	if err != nil {
		return fmt.Errorf("category not found: %w", err)
	}

	// Check if category is being used by spare parts
	var count int
	err = r.db.Get(&count, "SELECT COUNT(*) FROM spare_parts WHERE category = $1", categoryName)
	if err != nil {
		return fmt.Errorf("failed to check category usage: %w", err)
	}

	if count > 0 {
		return fmt.Errorf("cannot delete category '%s' because it is being used by %d spare parts", categoryName, count)
	}

	// Soft delete: set is_active to false instead of deleting the record
	_, err = r.db.Exec(`
		UPDATE spare_part_categories 
		SET is_active = false, updated_at = CURRENT_TIMESTAMP 
		WHERE id = $1
	`, id)
	if err != nil {
		return fmt.Errorf("failed to delete category: %w", err)
	}

	return nil
}

func (r *sparePartRepository) GetCategoryStats() ([]models.CategoryStats, error) {
	query := `
		SELECT 
			category as name,
			COUNT(*) as spare_part_count,
			COALESCE(SUM(stock_quantity), 0) as total_stock,
			COUNT(CASE WHEN stock_quantity <= minimum_stock THEN 1 END) as low_stock_count,
			COALESCE(SUM(selling_price * stock_quantity), 0) as total_value,
			COALESCE(AVG(selling_price), 0) as avg_price
		FROM spare_parts 
		WHERE category IS NOT NULL AND category != '' AND is_active = true
		GROUP BY category
		ORDER BY spare_part_count DESC
	`

	var stats []models.CategoryStats
	err := r.db.Select(&stats, query)
	if err != nil {
		return nil, fmt.Errorf("failed to get category stats: %w", err)
	}

	return stats, nil
}
