package service

import (
	"database/sql"
	"fmt"

	"golang.org/x/crypto/bcrypt"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
)

type UserService interface {
	CreateUser(req *models.UserCreateRequest) (*models.User, error)
	GetUser(id int) (*models.User, error)
	GetUserByUsername(username string) (*models.User, error)
	GetUserByEmail(email string) (*models.User, error)
	UpdateUser(id int, req *models.UserUpdateRequest) (*models.User, error)
	DeleteUser(id int) error
	ListUsers(page, limit int, search string, roleID *int, isActive *bool) ([]models.User, int, error)
	ChangePassword(userID int, oldPassword, newPassword string) error
	ResetPassword(userID int, newPassword string) error
	ToggleUserStatus(userID int) (*models.User, error)
	GetUsersByRole(roleName string) ([]models.User, error)
}

type userService struct {
	userRepo repository.UserRepository
}

func NewUserService(userRepo repository.UserRepository) UserService {
	return &userService{
		userRepo: userRepo,
	}
}

func (s *userService) CreateUser(req *models.UserCreateRequest) (*models.User, error) {
	// Check if username already exists
	_, err := s.userRepo.GetUserByUsername(req.Username)
	if err == nil {
		return nil, fmt.Errorf("username already exists")
	}
	if err != sql.ErrNoRows {
		return nil, fmt.Errorf("failed to check username: %w", err)
	}
	
	// Check if email already exists
	_, err = s.userRepo.GetUserByEmail(req.Email)
	if err == nil {
		return nil, fmt.Errorf("email already exists")
	}
	if err != sql.ErrNoRows {
		return nil, fmt.Errorf("failed to check email: %w", err)
	}
	
	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}
	req.Password = string(hashedPassword)
	
	user, err := s.userRepo.CreateUser(req)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}
	
	return user, nil
}

func (s *userService) GetUser(id int) (*models.User, error) {
	user, err := s.userRepo.GetUserByID(id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}
	
	return user, nil
}

func (s *userService) GetUserByUsername(username string) (*models.User, error) {
	if username == "" {
		return nil, fmt.Errorf("username is required")
	}
	
	user, err := s.userRepo.GetUserByUsername(username)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user by username: %w", err)
	}
	
	return user, nil
}

func (s *userService) GetUserByEmail(email string) (*models.User, error) {
	if email == "" {
		return nil, fmt.Errorf("email is required")
	}
	
	user, err := s.userRepo.GetUserByEmail(email)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user by email: %w", err)
	}
	
	return user, nil
}

func (s *userService) UpdateUser(id int, req *models.UserUpdateRequest) (*models.User, error) {
	// Check if user exists
	_, err := s.GetUser(id)
	if err != nil {
		return nil, err
	}
	
	// Check for duplicate username if being updated
	if req.Username != nil && *req.Username != "" {
		user, err := s.userRepo.GetUserByUsername(*req.Username)
		if err == nil && user.ID != id {
			return nil, fmt.Errorf("username already exists")
		}
		if err != nil && err != sql.ErrNoRows {
			return nil, fmt.Errorf("failed to check username: %w", err)
		}
	}
	
	// Check for duplicate email if being updated
	if req.Email != nil && *req.Email != "" {
		user, err := s.userRepo.GetUserByEmail(*req.Email)
		if err == nil && user.ID != id {
			return nil, fmt.Errorf("email already exists")
		}
		if err != nil && err != sql.ErrNoRows {
			return nil, fmt.Errorf("failed to check email: %w", err)
		}
	}
	
	user, err := s.userRepo.UpdateUser(id, req)
	if err != nil {
		return nil, fmt.Errorf("failed to update user: %w", err)
	}
	
	return user, nil
}

func (s *userService) DeleteUser(id int) error {
	// Check if user exists
	_, err := s.GetUser(id)
	if err != nil {
		return err
	}
	
	// TODO: Check if user has any related data (repairs, transactions, etc.)
	// For now, we'll allow deletion (soft delete anyway)
	
	err = s.userRepo.DeleteUser(id)
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}
	
	return nil
}

func (s *userService) ListUsers(page, limit int, search string, roleID *int, isActive *bool) ([]models.User, int, error) {
	// Validate pagination
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	if limit > 100 {
		limit = 100
	}
	
	users, total, err := s.userRepo.ListUsers(page, limit, search, roleID, isActive)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list users: %w", err)
	}
	
	return users, total, nil
}

func (s *userService) ChangePassword(userID int, oldPassword, newPassword string) error {
	// Get user
	user, err := s.GetUser(userID)
	if err != nil {
		return err
	}
	
	// Verify old password
	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(oldPassword))
	if err != nil {
		return fmt.Errorf("invalid old password")
	}
	
	// Hash new password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to hash new password: %w", err)
	}
	
	// Update password
	err = s.userRepo.UpdatePassword(userID, string(hashedPassword))
	if err != nil {
		return fmt.Errorf("failed to update password: %w", err)
	}
	
	return nil
}

func (s *userService) ResetPassword(userID int, newPassword string) error {
	// Check if user exists
	_, err := s.GetUser(userID)
	if err != nil {
		return err
	}
	
	// Hash new password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to hash new password: %w", err)
	}
	
	// Update password
	err = s.userRepo.UpdatePassword(userID, string(hashedPassword))
	if err != nil {
		return fmt.Errorf("failed to reset password: %w", err)
	}
	
	return nil
}

func (s *userService) ToggleUserStatus(userID int) (*models.User, error) {
	// Get current user
	user, err := s.GetUser(userID)
	if err != nil {
		return nil, err
	}
	
	// Toggle status
	newStatus := !user.IsActive
	req := &models.UserUpdateRequest{
		IsActive: &newStatus,
	}
	
	updatedUser, err := s.userRepo.UpdateUser(userID, req)
	if err != nil {
		return nil, fmt.Errorf("failed to toggle user status: %w", err)
	}
	
	return updatedUser, nil
}

func (s *userService) GetUsersByRole(roleName string) ([]models.User, error) {
	if roleName == "" {
		return nil, fmt.Errorf("role name is required")
	}
	
	users, err := s.userRepo.GetUsersByRole(roleName)
	if err != nil {
		return nil, fmt.Errorf("failed to get users by role: %w", err)
	}
	
	return users, nil
}