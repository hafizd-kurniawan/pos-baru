package repository

import (
	"fmt"
	"strings"

	"github.com/jmoiron/sqlx"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
)

type SupplierRepository interface {
	CreateSupplier(req *models.SupplierCreateRequest) (*models.Supplier, error)
	GetSupplierByID(id int) (*models.Supplier, error)
	GetSupplierByPhone(phone string) (*models.Supplier, error)
	GetSupplierByEmail(email string) (*models.Supplier, error)
	UpdateSupplier(id int, req *models.SupplierUpdateRequest) (*models.Supplier, error)
	DeleteSupplier(id int) error
	ListSuppliers(page, limit int, search string, isActive *bool) ([]models.Supplier, int, error)
	CheckSupplierExists(phone, email string, excludeID *int) (bool, error)
}

type supplierRepository struct {
	db *sqlx.DB
}

func NewSupplierRepository(db *sqlx.DB) SupplierRepository {
	return &supplierRepository{db: db}
}

func (r *supplierRepository) CreateSupplier(req *models.SupplierCreateRequest) (*models.Supplier, error) {
	supplier := &models.Supplier{}
	
	query := `
		INSERT INTO suppliers (name, contact_person, phone, email, address, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
		RETURNING id, name, contact_person, phone, email, address, is_active, created_at, updated_at`
	
	err := r.db.QueryRow(query, req.Name, req.ContactPerson, req.Phone, req.Email, req.Address).
		Scan(&supplier.ID, &supplier.Name, &supplier.ContactPerson, &supplier.Phone, 
			&supplier.Email, &supplier.Address, &supplier.IsActive, &supplier.CreatedAt, &supplier.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to create supplier: %w", err)
	}
	
	return supplier, nil
}

func (r *supplierRepository) GetSupplierByID(id int) (*models.Supplier, error) {
	supplier := &models.Supplier{}
	
	query := "SELECT * FROM suppliers WHERE id = $1"
	err := r.db.Get(supplier, query, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get supplier: %w", err)
	}
	
	return supplier, nil
}

func (r *supplierRepository) GetSupplierByPhone(phone string) (*models.Supplier, error) {
	supplier := &models.Supplier{}
	
	query := "SELECT * FROM suppliers WHERE phone = $1 AND is_active = true"
	err := r.db.Get(supplier, query, phone)
	if err != nil {
		return nil, fmt.Errorf("failed to get supplier by phone: %w", err)
	}
	
	return supplier, nil
}

func (r *supplierRepository) GetSupplierByEmail(email string) (*models.Supplier, error) {
	supplier := &models.Supplier{}
	
	query := "SELECT * FROM suppliers WHERE email = $1 AND is_active = true"
	err := r.db.Get(supplier, query, email)
	if err != nil {
		return nil, fmt.Errorf("failed to get supplier by email: %w", err)
	}
	
	return supplier, nil
}

func (r *supplierRepository) UpdateSupplier(id int, req *models.SupplierUpdateRequest) (*models.Supplier, error) {
	// Build dynamic update query
	setParts := []string{}
	args := []interface{}{}
	argIndex := 1
	
	if req.Name != nil {
		setParts = append(setParts, fmt.Sprintf("name = $%d", argIndex))
		args = append(args, *req.Name)
		argIndex++
	}
	
	if req.ContactPerson != nil {
		setParts = append(setParts, fmt.Sprintf("contact_person = $%d", argIndex))
		args = append(args, *req.ContactPerson)
		argIndex++
	}
	
	if req.Phone != nil {
		setParts = append(setParts, fmt.Sprintf("phone = $%d", argIndex))
		args = append(args, *req.Phone)
		argIndex++
	}
	
	if req.Email != nil {
		setParts = append(setParts, fmt.Sprintf("email = $%d", argIndex))
		args = append(args, *req.Email)
		argIndex++
	}
	
	if req.Address != nil {
		setParts = append(setParts, fmt.Sprintf("address = $%d", argIndex))
		args = append(args, *req.Address)
		argIndex++
	}
	
	if req.IsActive != nil {
		setParts = append(setParts, fmt.Sprintf("is_active = $%d", argIndex))
		args = append(args, *req.IsActive)
		argIndex++
	}
	
	if len(setParts) == 0 {
		return r.GetSupplierByID(id)
	}
	
	// Add updated_at
	setParts = append(setParts, fmt.Sprintf("updated_at = $%d", argIndex))
	args = append(args, "CURRENT_TIMESTAMP")
	argIndex++
	
	// Add WHERE clause
	args = append(args, id)
	
	query := fmt.Sprintf("UPDATE suppliers SET %s WHERE id = $%d", strings.Join(setParts, ", "), argIndex)
	
	_, err := r.db.Exec(query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to update supplier: %w", err)
	}
	
	return r.GetSupplierByID(id)
}

func (r *supplierRepository) DeleteSupplier(id int) error {
	// Soft delete by setting is_active to false
	query := "UPDATE suppliers SET is_active = false, updated_at = CURRENT_TIMESTAMP WHERE id = $1"
	
	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete supplier: %w", err)
	}
	
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check affected rows: %w", err)
	}
	
	if rowsAffected == 0 {
		return fmt.Errorf("supplier not found")
	}
	
	return nil
}

func (r *supplierRepository) ListSuppliers(page, limit int, search string, isActive *bool) ([]models.Supplier, int, error) {
	suppliers := []models.Supplier{}
	
	// Build base query
	baseQuery := "FROM suppliers WHERE 1=1"
	countQuery := "SELECT COUNT(*) " + baseQuery
	selectQuery := "SELECT * " + baseQuery
	
	args := []interface{}{}
	argIndex := 1
	
	// Add search filter
	if search != "" {
		searchCondition := fmt.Sprintf(" AND (name ILIKE $%d OR contact_person ILIKE $%d OR phone ILIKE $%d OR email ILIKE $%d)", 
			argIndex, argIndex, argIndex, argIndex)
		baseQuery += searchCondition
		countQuery += searchCondition
		selectQuery += searchCondition
		args = append(args, "%"+search+"%")
		argIndex++
	}
	
	// Add active filter
	if isActive != nil {
		activeCondition := fmt.Sprintf(" AND is_active = $%d", argIndex)
		baseQuery += activeCondition
		countQuery += activeCondition
		selectQuery += activeCondition
		args = append(args, *isActive)
		argIndex++
	}
	
	// Get total count
	var total int
	err := r.db.Get(&total, countQuery, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count suppliers: %w", err)
	}
	
	// Add pagination
	selectQuery += " ORDER BY created_at DESC"
	if limit > 0 {
		offset := (page - 1) * limit
		selectQuery += fmt.Sprintf(" LIMIT $%d OFFSET $%d", argIndex, argIndex+1)
		args = append(args, limit, offset)
	}
	
	// Execute query
	err = r.db.Select(&suppliers, selectQuery, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list suppliers: %w", err)
	}
	
	return suppliers, total, nil
}

func (r *supplierRepository) CheckSupplierExists(phone, email string, excludeID *int) (bool, error) {
	query := "SELECT COUNT(*) FROM suppliers WHERE is_active = true AND (phone = $1 OR email = $2)"
	args := []interface{}{phone, email}
	
	if excludeID != nil {
		query += " AND id != $3"
		args = append(args, *excludeID)
	}
	
	var count int
	err := r.db.Get(&count, query, args...)
	if err != nil {
		return false, fmt.Errorf("failed to check supplier existence: %w", err)
	}
	
	return count > 0, nil
}