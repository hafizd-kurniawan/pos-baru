package service

import (
	"fmt"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/middleware"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type AuthService interface {
	Login(req *models.LoginRequest) (*models.LoginResponse, error)
	Register(req *models.UserCreateRequest) (*models.User, error)
	GetUserProfile(userID int) (*models.User, error)
}

type authService struct {
	userRepo      repository.UserRepository
	jwtMiddleware *middleware.JWTMiddleware
}

func NewAuthService(userRepo repository.UserRepository, jwtMiddleware *middleware.JWTMiddleware) AuthService {
	return &authService{
		userRepo:      userRepo,
		jwtMiddleware: jwtMiddleware,
	}
}

func (s *authService) Login(req *models.LoginRequest) (*models.LoginResponse, error) {
	// Get user by username
	user, err := s.userRepo.GetByUsername(req.Username)
	if err != nil {
		return nil, fmt.Errorf("invalid username or password")
	}

	// Check if user is active
	if !user.IsActive {
		return nil, fmt.Errorf("user account is inactive")
	}

	// Verify password
	if !utils.CheckPassword(req.Password, user.Password) {
		return nil, fmt.Errorf("invalid username or password")
	}

	// Get user with role information
	userWithRole, err := s.userRepo.GetUserWithRole(user.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user role information: %w", err)
	}

	// Generate JWT token
	token, err := s.jwtMiddleware.GenerateToken(userWithRole)
	if err != nil {
		return nil, fmt.Errorf("failed to generate token: %w", err)
	}

	// Don't include password in response
	userWithRole.Password = ""

	return &models.LoginResponse{
		Token: token,
		User:  *userWithRole,
	}, nil
}

func (s *authService) Register(req *models.UserCreateRequest) (*models.User, error) {
	// Check if username already exists
	existingUser, _ := s.userRepo.GetByUsername(req.Username)
	if existingUser != nil {
		return nil, fmt.Errorf("username already exists")
	}

	// Check if email already exists
	existingUser, _ = s.userRepo.GetByEmail(req.Email)
	if existingUser != nil {
		return nil, fmt.Errorf("email already exists")
	}

	// Hash password
	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	// Create user request with hashed password
	userReq := &models.UserCreateRequest{
		Username: req.Username,
		Email:    req.Email,
		Password: hashedPassword,
		FullName: req.FullName,
		Phone:    req.Phone,
		RoleID:   req.RoleID,
	}

	// Create user
	user, err := s.userRepo.Create(userReq)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	// Don't include password in response
	user.Password = ""

	return user, nil
}

func (s *authService) GetUserProfile(userID int) (*models.User, error) {
	user, err := s.userRepo.GetUserWithRole(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user profile: %w", err)
	}

	// Don't include password in response
	user.Password = ""

	return user, nil
}