package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type UserHandler struct {
	userService service.UserService
}

func NewUserHandler(userService service.UserService) *UserHandler {
	return &UserHandler{
		userService: userService,
	}
}

// CreateUser creates a new user (admin only)
func (h *UserHandler) CreateUser(c *gin.Context) {
	var req models.UserCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid request body: "+err.Error())
		return
	}
	
	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Validation failed: "+err.Error())
		return
	}
	
	user, err := h.userService.CreateUser(&req)
	if err != nil {
		if err.Error() == "username already exists" || err.Error() == "email already exists" {
			utils.SendError(c, 409, "Conflict", err.Error())
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to create user: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "User created successfully", user)
}

// GetUser retrieves a user by ID
func (h *UserHandler) GetUser(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid user ID format")
		return
	}
	
	user, err := h.userService.GetUser(id)
	if err != nil {
		if err.Error() == "user not found" {
			utils.SendError(c, 404, "Not Found", "User not found")
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to get user: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "User retrieved successfully", user)
}

// GetUserByUsername retrieves a user by username
func (h *UserHandler) GetUserByUsername(c *gin.Context) {
	username := c.Param("username")
	if username == "" {
		utils.SendError(c, 400, "Bad Request", "Username is required")
		return
	}
	
	user, err := h.userService.GetUserByUsername(username)
	if err != nil {
		if err.Error() == "user not found" {
			utils.SendError(c, 404, "Not Found", "User not found")
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to get user: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "User retrieved successfully", user)
}

// GetUserByEmail retrieves a user by email
func (h *UserHandler) GetUserByEmail(c *gin.Context) {
	email := c.Param("email")
	if email == "" {
		utils.SendError(c, 400, "Bad Request", "Email is required")
		return
	}
	
	user, err := h.userService.GetUserByEmail(email)
	if err != nil {
		if err.Error() == "user not found" {
			utils.SendError(c, 404, "Not Found", "User not found")
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to get user: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "User retrieved successfully", user)
}

// UpdateUser updates an existing user
func (h *UserHandler) UpdateUser(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid user ID format")
		return
	}
	
	var req models.UserUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid request body: "+err.Error())
		return
	}
	
	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Validation failed: "+err.Error())
		return
	}
	
	user, err := h.userService.UpdateUser(id, &req)
	if err != nil {
		if err.Error() == "user not found" {
			utils.SendError(c, 404, "Not Found", "User not found")
			return
		}
		if err.Error() == "username already exists" || err.Error() == "email already exists" {
			utils.SendError(c, 409, "Conflict", err.Error())
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to update user: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "User updated successfully", user)
}

// DeleteUser deletes a user (admin only)
func (h *UserHandler) DeleteUser(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid user ID format")
		return
	}
	
	err = h.userService.DeleteUser(id)
	if err != nil {
		if err.Error() == "user not found" {
			utils.SendError(c, 404, "Not Found", "User not found")
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to delete user: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "User deleted successfully", gin.H{
		"deleted_id": id,
	})
}

// ListUsers retrieves users with pagination and filters
func (h *UserHandler) ListUsers(c *gin.Context) {
	// Parse query parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	search := c.Query("search")
	
	var roleID *int
	if roleStr := c.Query("role_id"); roleStr != "" {
		if parsedRole, err := strconv.Atoi(roleStr); err == nil {
			roleID = &parsedRole
		}
	}
	
	var isActive *bool
	if activeStr := c.Query("is_active"); activeStr != "" {
		active, err := strconv.ParseBool(activeStr)
		if err == nil {
			isActive = &active
		}
	}
	
	users, total, err := h.userService.ListUsers(page, limit, search, roleID, isActive)
	if err != nil {
		utils.SendError(c, 500, "Internal Server Error", "Failed to list users: "+err.Error())
		return
	}
	
	utils.SendSuccessWithMeta(c, "Users retrieved successfully", users, utils.CalculatePaginationMeta(page, limit, int64(total)))
}

// GetActiveUsers retrieves only active users
func (h *UserHandler) GetActiveUsers(c *gin.Context) {
	// Parse query parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	search := c.Query("search")
	
	var roleID *int
	if roleStr := c.Query("role_id"); roleStr != "" {
		if parsedRole, err := strconv.Atoi(roleStr); err == nil {
			roleID = &parsedRole
		}
	}
	
	active := true
	users, total, err := h.userService.ListUsers(page, limit, search, roleID, &active)
	if err != nil {
		utils.SendError(c, 500, "Internal Server Error", "Failed to list active users: "+err.Error())
		return
	}
	
	utils.SendSuccessWithMeta(c, "Active users retrieved successfully", users, utils.CalculatePaginationMeta(page, limit, int64(total)))
}

// ChangePassword allows users to change their own password
func (h *UserHandler) ChangePassword(c *gin.Context) {
	// Get user ID from context
	userID, exists := c.Get("user_id")
	if !exists {
		utils.SendError(c, 401, "Unauthorized", "User ID not found in context")
		return
	}
	
	var req struct {
		OldPassword string `json:"old_password" validate:"required,min=6"`
		NewPassword string `json:"new_password" validate:"required,min=6"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid request body: "+err.Error())
		return
	}
	
	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Validation failed: "+err.Error())
		return
	}
	
	err := h.userService.ChangePassword(userID.(int), req.OldPassword, req.NewPassword)
	if err != nil {
		if err.Error() == "invalid old password" {
			utils.SendError(c, 400, "Bad Request", "Invalid old password")
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to change password: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Password changed successfully", gin.H{
		"message": "Password has been updated",
	})
}

// ResetPassword allows admin to reset user password
func (h *UserHandler) ResetPassword(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid user ID format")
		return
	}
	
	var req struct {
		NewPassword string `json:"new_password" validate:"required,min=6"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid request body: "+err.Error())
		return
	}
	
	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Validation failed: "+err.Error())
		return
	}
	
	err = h.userService.ResetPassword(id, req.NewPassword)
	if err != nil {
		if err.Error() == "user not found" {
			utils.SendError(c, 404, "Not Found", "User not found")
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to reset password: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Password reset successfully", gin.H{
		"user_id": id,
		"message": "Password has been reset",
	})
}

// ToggleUserStatus toggles user active/inactive status
func (h *UserHandler) ToggleUserStatus(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid user ID format")
		return
	}
	
	user, err := h.userService.ToggleUserStatus(id)
	if err != nil {
		if err.Error() == "user not found" {
			utils.SendError(c, 404, "Not Found", "User not found")
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to toggle user status: "+err.Error())
		return
	}
	
	status := "activated"
	if !user.IsActive {
		status = "deactivated"
	}
	
	utils.SendSuccess(c, "User status updated successfully", gin.H{
		"user_id":    user.ID,
		"is_active":  user.IsActive,
		"status":     status,
	})
}

// GetUsersByRole retrieves users by role name
func (h *UserHandler) GetUsersByRole(c *gin.Context) {
	roleName := c.Param("role")
	if roleName == "" {
		utils.SendError(c, 400, "Bad Request", "Role name is required")
		return
	}
	
	users, err := h.userService.GetUsersByRole(roleName)
	if err != nil {
		utils.SendError(c, 500, "Internal Server Error", "Failed to get users by role: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Users retrieved successfully", gin.H{
		"role":  roleName,
		"users": users,
		"count": len(users),
	})
}