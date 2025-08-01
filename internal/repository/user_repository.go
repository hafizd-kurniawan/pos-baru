package repository

import (
	"database/sql"
	"fmt"
	"strings"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/pkg/database"
)

type UserRepository interface {
	Create(user *models.UserCreateRequest) (*models.User, error)
	GetByID(id int) (*models.User, error)
	GetByUsername(username string) (*models.User, error)
	GetByEmail(email string) (*models.User, error)
	Update(id int, req *models.UserUpdateRequest) (*models.User, error)
	Delete(id int) error
	List(page, limit int) ([]models.User, int64, error)
	GetUserWithRole(id int) (*models.User, error)
}

type userRepository struct {
	db *database.Database
}

func NewUserRepository(db *database.Database) UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) Create(req *models.UserCreateRequest) (*models.User, error) {
	query := `
		INSERT INTO users (username, email, password, full_name, phone, role_id)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, username, email, full_name, phone, role_id, is_active, created_at, updated_at`

	var user models.User
	err := r.db.Get(&user, query, req.Username, req.Email, req.Password, req.FullName, req.Phone, req.RoleID)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return &user, nil
}

func (r *userRepository) GetByID(id int) (*models.User, error) {
	query := `
		SELECT id, username, email, full_name, phone, role_id, is_active, created_at, updated_at
		FROM users 
		WHERE id = $1`

	var user models.User
	err := r.db.Get(&user, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return &user, nil
}

func (r *userRepository) GetByUsername(username string) (*models.User, error) {
	query := `
		SELECT id, username, email, password, full_name, phone, role_id, is_active, created_at, updated_at
		FROM users 
		WHERE username = $1`

	var user models.User
	err := r.db.Get(&user, query, username)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return &user, nil
}

func (r *userRepository) GetByEmail(email string) (*models.User, error) {
	query := `
		SELECT id, username, email, full_name, phone, role_id, is_active, created_at, updated_at
		FROM users 
		WHERE email = $1`

	var user models.User
	err := r.db.Get(&user, query, email)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return &user, nil
}

func (r *userRepository) GetUserWithRole(id int) (*models.User, error) {
	query := `
		SELECT 
			u.id, u.username, u.email, u.full_name, u.phone, u.role_id, u.is_active, u.created_at, u.updated_at,
			r.id as "role.id", r.name as "role.name", r.description as "role.description", r.created_at as "role.created_at"
		FROM users u
		JOIN roles r ON u.role_id = r.id
		WHERE u.id = $1`

	var user models.User
	err := r.db.Get(&user, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user with role: %w", err)
	}

	return &user, nil
}

func (r *userRepository) Update(id int, req *models.UserUpdateRequest) (*models.User, error) {
	// Build dynamic update query
	setParts := []string{"updated_at = CURRENT_TIMESTAMP"}
	args := []interface{}{}
	argCounter := 1

	if req.Username != nil {
		setParts = append(setParts, fmt.Sprintf("username = $%d", argCounter))
		args = append(args, *req.Username)
		argCounter++
	}
	if req.Email != nil {
		setParts = append(setParts, fmt.Sprintf("email = $%d", argCounter))
		args = append(args, *req.Email)
		argCounter++
	}
	if req.FullName != nil {
		setParts = append(setParts, fmt.Sprintf("full_name = $%d", argCounter))
		args = append(args, *req.FullName)
		argCounter++
	}
	if req.Phone != nil {
		setParts = append(setParts, fmt.Sprintf("phone = $%d", argCounter))
		args = append(args, *req.Phone)
		argCounter++
	}
	if req.RoleID != nil {
		setParts = append(setParts, fmt.Sprintf("role_id = $%d", argCounter))
		args = append(args, *req.RoleID)
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
		UPDATE users 
		SET %s
		WHERE id = $%d
		RETURNING id, username, email, full_name, phone, role_id, is_active, created_at, updated_at`,
		strings.Join(setParts, ", "), argCounter)

	var user models.User
	err := r.db.Get(&user, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to update user: %w", err)
	}

	return &user, nil
}

func (r *userRepository) Delete(id int) error {
	query := `DELETE FROM users WHERE id = $1`
	
	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("user not found")
	}

	return nil
}

func (r *userRepository) List(page, limit int) ([]models.User, int64, error) {
	offset := (page - 1) * limit

	// Get total count
	var total int64
	countQuery := `SELECT COUNT(*) FROM users`
	err := r.db.Get(&total, countQuery)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count users: %w", err)
	}

	// Get users with pagination
	query := `
		SELECT 
			u.id, u.username, u.email, u.full_name, u.phone, u.role_id, u.is_active, u.created_at, u.updated_at,
			r.id as "role.id", r.name as "role.name", r.description as "role.description", r.created_at as "role.created_at"
		FROM users u
		JOIN roles r ON u.role_id = r.id
		ORDER BY u.created_at DESC
		LIMIT $1 OFFSET $2`

	var users []models.User
	err = r.db.Select(&users, query, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list users: %w", err)
	}

	return users, total, nil
}