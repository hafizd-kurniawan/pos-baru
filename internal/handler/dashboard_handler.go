package handler

import (
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type DashboardHandler struct {
	dashboardService service.DashboardService
}

func NewDashboardHandler(dashboardService service.DashboardService) *DashboardHandler {
	return &DashboardHandler{
		dashboardService: dashboardService,
	}
}

// GetDashboard retrieves role-based dashboard data
func (h *DashboardHandler) GetDashboard(c *gin.Context) {
	// Get role from context (set by auth middleware)
	roleName, exists := c.Get("role_name")
	if !exists {
		utils.SendError(c, 401, "Unauthorized", "Role not found in context")
		return
	}
	
	roleStr, ok := roleName.(string)
	if !ok {
		utils.SendError(c, 500, "Internal Server Error", "Invalid role data in context")
		return
	}
	
	// Route to appropriate dashboard based on role
	switch roleStr {
	case "admin":
		dashboard, err := h.dashboardService.GetAdminDashboard()
		if err != nil {
			utils.SendError(c, 500, "Internal Server Error", "Failed to get admin dashboard: "+err.Error())
			return
		}
		utils.SendSuccess(c, "Admin dashboard retrieved successfully", dashboard)
		
	case "kasir":
		dashboard, err := h.dashboardService.GetCashierDashboard()
		if err != nil {
			utils.SendError(c, 500, "Internal Server Error", "Failed to get cashier dashboard: "+err.Error())
			return
		}
		utils.SendSuccess(c, "Cashier dashboard retrieved successfully", dashboard)
		
	case "mekanik":
		userID, exists := c.Get("user_id")
		if !exists {
			utils.SendError(c, 401, "Unauthorized", "User ID not found in context")
			return
		}
		
		dashboard, err := h.dashboardService.GetMechanicDashboard(userID.(int))
		if err != nil {
			utils.SendError(c, 500, "Internal Server Error", "Failed to get mechanic dashboard: "+err.Error())
			return
		}
		utils.SendSuccess(c, "Mechanic dashboard retrieved successfully", dashboard)
		
	default:
		utils.SendError(c, 403, "Forbidden", "Invalid user role")
		return
	}
}

// GetAdminDashboard retrieves admin-specific dashboard data
func (h *DashboardHandler) GetAdminDashboard(c *gin.Context) {
	dashboard, err := h.dashboardService.GetAdminDashboard()
	if err != nil {
		utils.SendError(c, 500, "Internal Server Error", "Failed to get admin dashboard: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Admin dashboard retrieved successfully", dashboard)
}

// GetCashierDashboard retrieves cashier-specific dashboard data
func (h *DashboardHandler) GetCashierDashboard(c *gin.Context) {
	dashboard, err := h.dashboardService.GetCashierDashboard()
	if err != nil {
		utils.SendError(c, 500, "Internal Server Error", "Failed to get cashier dashboard: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Cashier dashboard retrieved successfully", dashboard)
}

// GetMechanicDashboard retrieves mechanic-specific dashboard data
func (h *DashboardHandler) GetMechanicDashboard(c *gin.Context) {
	// Get mechanic ID from path parameter or use current user
	mechanicIDStr := c.Param("mechanic_id")
	var mechanicID int
	var err error
	
	if mechanicIDStr != "" {
		mechanicID, err = strconv.Atoi(mechanicIDStr)
		if err != nil {
			utils.SendError(c, 400, "Bad Request", "Invalid mechanic ID format")
			return
		}
	} else {
		// Use current user ID if no specific mechanic ID provided
		userID, exists := c.Get("user_id")
		if !exists {
			utils.SendError(c, 401, "Unauthorized", "User ID not found in context")
			return
		}
		
		mechanicID = userID.(int)
	}
	
	dashboard, err := h.dashboardService.GetMechanicDashboard(mechanicID)
	if err != nil {
		utils.SendError(c, 500, "Internal Server Error", "Failed to get mechanic dashboard: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Mechanic dashboard retrieved successfully", dashboard)
}

// CreateDailyClosing creates a daily closing report
func (h *DashboardHandler) CreateDailyClosing(c *gin.Context) {
	// Get user ID from context
	userID, exists := c.Get("user_id")
	if !exists {
		utils.SendError(c, 401, "Unauthorized", "User ID not found in context")
		return
	}
	
	// Parse request body
	var req models.DailyClosingCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid request body: "+err.Error())
		return
	}
	
	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Validation failed: "+err.Error())
		return
	}
	
	// Create daily closing
	closing, err := h.dashboardService.CreateDailyClosing(userID.(int), &req)
	if err != nil {
		utils.SendError(c, 500, "Internal Server Error", "Failed to create daily closing: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Daily closing created successfully", closing)
}

// CreateMonthlyClosing creates a monthly closing report
func (h *DashboardHandler) CreateMonthlyClosing(c *gin.Context) {
	// Get user ID from context
	userID, exists := c.Get("user_id")
	if !exists {
		utils.SendError(c, 401, "Unauthorized", "User ID not found in context")
		return
	}
	
	// Parse request body
	var req models.MonthlyClosingCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid request body: "+err.Error())
		return
	}
	
	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Validation failed: "+err.Error())
		return
	}
	
	// Create monthly closing
	closing, err := h.dashboardService.CreateMonthlyClosing(userID.(int), &req)
	if err != nil {
		utils.SendError(c, 500, "Internal Server Error", "Failed to create monthly closing: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Monthly closing created successfully", closing)
}

// UpdateMetrics manually updates dashboard metrics
func (h *DashboardHandler) UpdateMetrics(c *gin.Context) {
	err := h.dashboardService.UpdateMetrics()
	if err != nil {
		utils.SendError(c, 500, "Internal Server Error", "Failed to update metrics: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Dashboard metrics updated successfully", gin.H{
		"updated_at": time.Now(),
	})
}