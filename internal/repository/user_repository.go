package repository

import (
	"database/sql"
	"fmt"
	"strings"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/pkg/database"
)

type UserRepository interface {
	CreateUser(user *models.UserCreateRequest) (*models.User, error)
	GetUserByID(id int) (*models.User, error)
	GetUserByUsername(username string) (*models.User, error)
	GetUserByEmail(email string) (*models.User, error)
	UpdateUser(id int, req *models.UserUpdateRequest) (*models.User, error)
	DeleteUser(id int) error
	ListUsers(page, limit int, search string, roleID *int, isActive *bool) ([]models.User, int, error)
	UpdatePassword(userID int, hashedPassword string) error
	GetUsersByRole(roleName string) ([]models.User, error)
	GetUserWithRole(id int) (*models.User, error)
	
	// Legacy methods for auth service compatibility
	Create(user *models.UserCreateRequest) (*models.User, error)
	GetByID(id int) (*models.User, error)
	GetByUsername(username string) (*models.User, error)
	GetByEmail(email string) (*models.User, error)
	Update(id int, req *models.UserUpdateRequest) (*models.User, error)
	Delete(id int) error
	List(page, limit int) ([]models.User, int64, error)
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

// New methods for user service
func (r *userRepository) CreateUser(req *models.UserCreateRequest) (*models.User, error) {
	return r.Create(req)
}

func (r *userRepository) GetUserByID(id int) (*models.User, error) {
	return r.GetByID(id)
}

func (r *userRepository) GetUserByUsername(username string) (*models.User, error) {
	return r.GetByUsername(username)
}

func (r *userRepository) GetUserByEmail(email string) (*models.User, error) {
	return r.GetByEmail(email)
}

func (r *userRepository) UpdateUser(id int, req *models.UserUpdateRequest) (*models.User, error) {
	return r.Update(id, req)
}

func (r *userRepository) DeleteUser(id int) error {
	return r.Delete(id)
}

func (r *userRepository) ListUsers(page, limit int, search string, roleID *int, isActive *bool) ([]models.User, int, error) {
	// Build base query
	baseQuery := `FROM users u JOIN roles r ON u.role_id = r.id WHERE 1=1`
	countQuery := "SELECT COUNT(*) " + baseQuery
	selectQuery := `
		SELECT 
			u.id, u.username, u.email, u.full_name, u.phone, u.role_id, u.is_active, u.created_at, u.updated_at,
			r.id as "role.id", r.name as "role.name", r.description as "role.description", r.created_at as "role.created_at"
		` + baseQuery
	
	args := []interface{}{}
	argIndex := 1
	
	// Add search filter
	if search != "" {
		searchCondition := fmt.Sprintf(" AND (u.username ILIKE $%d OR u.full_name ILIKE $%d OR u.email ILIKE $%d)", 
			argIndex, argIndex, argIndex)
		baseQuery += searchCondition
		countQuery += searchCondition
		selectQuery += searchCondition
		args = append(args, "%"+search+"%")
		argIndex++
	}
	
	// Add role filter
	if roleID != nil {
		roleCondition := fmt.Sprintf(" AND u.role_id = $%d", argIndex)
		baseQuery += roleCondition
		countQuery += roleCondition
		selectQuery += roleCondition
		args = append(args, *roleID)
		argIndex++
	}
	
	// Add active filter
	if isActive != nil {
		activeCondition := fmt.Sprintf(" AND u.is_active = $%d", argIndex)
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
		return nil, 0, fmt.Errorf("failed to count users: %w", err)
	}
	
	// Add pagination
	selectQuery += " ORDER BY u.created_at DESC"
	if limit > 0 {
		offset := (page - 1) * limit
		selectQuery += fmt.Sprintf(" LIMIT $%d OFFSET $%d", argIndex, argIndex+1)
		args = append(args, limit, offset)
	}
	
	// Execute query
	var users []models.User
	err = r.db.Select(&users, selectQuery, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list users: %w", err)
	}
	
	return users, total, nil
}

func (r *userRepository) UpdatePassword(userID int, hashedPassword string) error {
	query := "UPDATE users SET password = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2"
	
	result, err := r.db.Exec(query, hashedPassword, userID)
	if err != nil {
		return fmt.Errorf("failed to update password: %w", err)
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

func (r *userRepository) GetUsersByRole(roleName string) ([]models.User, error) {
	query := `
		SELECT 
			u.id, u.username, u.email, u.full_name, u.phone, u.role_id, u.is_active, u.created_at, u.updated_at,
			r.id as "role.id", r.name as "role.name", r.description as "role.description", r.created_at as "role.created_at"
		FROM users u
		JOIN roles r ON u.role_id = r.id
		WHERE r.name = $1 AND u.is_active = true
		ORDER BY u.full_name`
	
	var users []models.User
	err := r.db.Select(&users, query, roleName)
	if err != nil {
		return nil, fmt.Errorf("failed to get users by role: %w", err)
	}
	
	return users, nil
}