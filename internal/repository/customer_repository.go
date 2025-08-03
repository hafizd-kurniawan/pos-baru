package repository

import (
	"database/sql"
	"fmt"
	"strings"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/pkg/database"
)

type CustomerRepository interface {
	Create(req *models.CustomerCreateRequest) (*models.Customer, error)
	GetByID(id int) (*models.Customer, error)
	Update(id int, req *models.CustomerUpdateRequest) (*models.Customer, error)
	Delete(id int) error
	List(page, limit int) ([]models.Customer, int64, error)
	GetByPhone(phone string) (*models.Customer, error)
	GetByEmail(email string) (*models.Customer, error)
}

type customerRepository struct {
	db *database.Database
}

func NewCustomerRepository(db *database.Database) CustomerRepository {
	return &customerRepository{db: db}
}

func (r *customerRepository) Create(req *models.CustomerCreateRequest) (*models.Customer, error) {
	query := `
		INSERT INTO customers (name, phone, email, address, id_card_number)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, name, phone, email, address, id_card_number, created_at, updated_at`

	var customer models.Customer
	err := r.db.Get(&customer, query, req.Name, req.Phone, req.Email, req.Address, req.IDCardNumber)
	if err != nil {
		return nil, fmt.Errorf("failed to create customer: %w", err)
	}

	return &customer, nil
}

func (r *customerRepository) GetByID(id int) (*models.Customer, error) {
	query := `
		SELECT id, name, phone, email, address, id_card_number, created_at, updated_at
		FROM customers 
		WHERE id = $1`

	var customer models.Customer
	err := r.db.Get(&customer, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("customer not found")
		}
		return nil, fmt.Errorf("failed to get customer: %w", err)
	}

	return &customer, nil
}

func (r *customerRepository) GetByPhone(phone string) (*models.Customer, error) {
	query := `
		SELECT id, name, phone, email, address, id_card_number, created_at, updated_at
		FROM customers 
		WHERE phone = $1`

	var customer models.Customer
	err := r.db.Get(&customer, query, phone)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("customer not found")
		}
		return nil, fmt.Errorf("failed to get customer: %w", err)
	}

	return &customer, nil
}

func (r *customerRepository) GetByEmail(email string) (*models.Customer, error) {
	query := `
		SELECT id, name, phone, email, address, id_card_number, created_at, updated_at
		FROM customers 
		WHERE email = $1`

	var customer models.Customer
	err := r.db.Get(&customer, query, email)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("customer not found")
		}
		return nil, fmt.Errorf("failed to get customer: %w", err)
	}

	return &customer, nil
}

func (r *customerRepository) Update(id int, req *models.CustomerUpdateRequest) (*models.Customer, error) {
	// Build dynamic update query
	setParts := []string{"updated_at = CURRENT_TIMESTAMP"}
	args := []interface{}{}
	argCounter := 1

	if req.Name != nil {
		setParts = append(setParts, fmt.Sprintf("name = $%d", argCounter))
		args = append(args, *req.Name)
		argCounter++
	}
	if req.Phone != nil {
		setParts = append(setParts, fmt.Sprintf("phone = $%d", argCounter))
		args = append(args, *req.Phone)
		argCounter++
	}
	if req.Email != nil {
		setParts = append(setParts, fmt.Sprintf("email = $%d", argCounter))
		args = append(args, *req.Email)
		argCounter++
	}
	if req.Address != nil {
		setParts = append(setParts, fmt.Sprintf("address = $%d", argCounter))
		args = append(args, *req.Address)
		argCounter++
	}
	if req.IDCardNumber != nil {
		setParts = append(setParts, fmt.Sprintf("id_card_number = $%d", argCounter))
		args = append(args, *req.IDCardNumber)
		argCounter++
	}

	// Add WHERE clause parameter
	args = append(args, id)

	query := fmt.Sprintf(`
		UPDATE customers 
		SET %s
		WHERE id = $%d
		RETURNING id, name, phone, email, address, id_card_number, created_at, updated_at`,
		strings.Join(setParts, ", "), argCounter)

	var customer models.Customer
	err := r.db.Get(&customer, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to update customer: %w", err)
	}

	return &customer, nil
}

func (r *customerRepository) Delete(id int) error {
	query := `DELETE FROM customers WHERE id = $1`
	
	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete customer: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("customer not found")
	}

	return nil
}

func (r *customerRepository) List(page, limit int) ([]models.Customer, int64, error) {
	offset := (page - 1) * limit

	// Get total count
	var total int64
	countQuery := `SELECT COUNT(*) FROM customers`
	err := r.db.Get(&total, countQuery)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count customers: %w", err)
	}

	// Get customers with pagination
	query := `
		SELECT id, name, phone, email, address, id_card_number, created_at, updated_at
		FROM customers
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2`

	var customers []models.Customer
	err = r.db.Select(&customers, query, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list customers: %w", err)
	}

	return customers, total, nil
}