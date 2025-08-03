package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/middleware"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type AuthHandler struct {
	authService service.AuthService
}

func NewAuthHandler(authService service.AuthService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
	}
}

// Login godoc
// @Summary User login
// @Description Authenticate user and return JWT token
// @Tags auth
// @Accept json
// @Produce json
// @Param request body models.LoginRequest true "Login credentials"
// @Success 200 {object} utils.APIResponse{data=models.LoginResponse}
// @Failure 400 {object} utils.APIResponse
// @Failure 401 {object} utils.APIResponse
// @Router /api/auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendBadRequest(c, "Invalid request format", err.Error())
		return
	}

	response, err := h.authService.Login(&req)
	if err != nil {
		utils.SendError(c, http.StatusUnauthorized, "Login failed", err.Error())
		return
	}

	utils.SendSuccess(c, "Login successful", response)
}

// Register godoc
// @Summary Register new user
// @Description Register a new user (admin only)
// @Tags auth
// @Accept json
// @Produce json
// @Param request body models.UserCreateRequest true "User data"
// @Success 201 {object} utils.APIResponse{data=models.User}
// @Failure 400 {object} utils.APIResponse
// @Failure 409 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/auth/register [post]
func (h *AuthHandler) Register(c *gin.Context) {
	var req models.UserCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendBadRequest(c, "Invalid request format", err.Error())
		return
	}

	user, err := h.authService.Register(&req)
	if err != nil {
		if err.Error() == "username already exists" || err.Error() == "email already exists" {
			utils.SendConflict(c, "User already exists", err.Error())
			return
		}
		utils.SendInternalServerError(c, "Registration failed", err.Error())
		return
	}

	utils.SendCreated(c, "User registered successfully", user)
}

// GetProfile godoc
// @Summary Get user profile
// @Description Get current user's profile information
// @Tags auth
// @Produce json
// @Success 200 {object} utils.APIResponse{data=models.User}
// @Failure 401 {object} utils.APIResponse
// @Failure 404 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/auth/profile [get]
func (h *AuthHandler) GetProfile(c *gin.Context) {
	userID, _, _, _, err := middleware.GetUserFromContext(c)
	if err != nil {
		utils.SendUnauthorized(c, "Invalid token")
		return
	}

	user, err := h.authService.GetUserProfile(userID)
	if err != nil {
		utils.SendNotFound(c, "User not found")
		return
	}

	utils.SendSuccess(c, "Profile retrieved successfully", user)
}

type VehicleHandler struct {
	vehicleService service.VehicleService
}

func NewVehicleHandler(vehicleService service.VehicleService) *VehicleHandler {
	return &VehicleHandler{
		vehicleService: vehicleService,
	}
}

// CreateVehicle godoc
// @Summary Create new vehicle
// @Description Create a new vehicle record
// @Tags vehicles
// @Accept json
// @Produce json
// @Param request body models.VehicleCreateRequest true "Vehicle data"
// @Success 201 {object} utils.APIResponse{data=models.Vehicle}
// @Failure 400 {object} utils.APIResponse
// @Failure 409 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/vehicles [post]
func (h *VehicleHandler) CreateVehicle(c *gin.Context) {
	var req models.VehicleCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendBadRequest(c, "Invalid request format", err.Error())
		return
	}

	userID, _, _, _, err := middleware.GetUserFromContext(c)
	if err != nil {
		utils.SendUnauthorized(c, "Invalid token")
		return
	}

	vehicle, err := h.vehicleService.Create(&req, userID)
	if err != nil {
		if err.Error() == "vehicle code already exists" {
			utils.SendConflict(c, "Vehicle already exists", err.Error())
			return
		}
		utils.SendInternalServerError(c, "Failed to create vehicle", err.Error())
		return
	}

	utils.SendCreated(c, "Vehicle created successfully", vehicle)
}

// GetVehicle godoc
// @Summary Get vehicle by ID
// @Description Get vehicle details by ID
// @Tags vehicles
// @Produce json
// @Param id path int true "Vehicle ID"
// @Success 200 {object} utils.APIResponse{data=models.Vehicle}
// @Failure 404 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/vehicles/{id} [get]
func (h *VehicleHandler) GetVehicle(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.SendBadRequest(c, "Invalid vehicle ID", err.Error())
		return
	}

	vehicle, err := h.vehicleService.GetByID(id)
	if err != nil {
		utils.SendNotFound(c, "Vehicle not found")
		return
	}

	utils.SendSuccess(c, "Vehicle retrieved successfully", vehicle)
}

// UpdateVehicle godoc
// @Summary Update vehicle
// @Description Update vehicle information
// @Tags vehicles
// @Accept json
// @Produce json
// @Param id path int true "Vehicle ID"
// @Param request body models.VehicleUpdateRequest true "Vehicle update data"
// @Success 200 {object} utils.APIResponse{data=models.Vehicle}
// @Failure 400 {object} utils.APIResponse
// @Failure 404 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/vehicles/{id} [put]
func (h *VehicleHandler) UpdateVehicle(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.SendBadRequest(c, "Invalid vehicle ID", err.Error())
		return
	}

	var req models.VehicleUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendBadRequest(c, "Invalid request format", err.Error())
		return
	}

	vehicle, err := h.vehicleService.Update(id, &req)
	if err != nil {
		if err.Error() == "vehicle not found" {
			utils.SendNotFound(c, "Vehicle not found")
			return
		}
		utils.SendInternalServerError(c, "Failed to update vehicle", err.Error())
		return
	}

	utils.SendSuccess(c, "Vehicle updated successfully", vehicle)
}

// DeleteVehicle godoc
// @Summary Delete vehicle
// @Description Delete vehicle record
// @Tags vehicles
// @Param id path int true "Vehicle ID"
// @Success 200 {object} utils.APIResponse
// @Failure 400 {object} utils.APIResponse
// @Failure 404 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/vehicles/{id} [delete]
func (h *VehicleHandler) DeleteVehicle(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.SendBadRequest(c, "Invalid vehicle ID", err.Error())
		return
	}

	err = h.vehicleService.Delete(id)
	if err != nil {
		if err.Error() == "vehicle not found" {
			utils.SendNotFound(c, "Vehicle not found")
			return
		}
		if err.Error() == "cannot delete sold vehicle" {
			utils.SendBadRequest(c, "Cannot delete sold vehicle", err.Error())
			return
		}
		utils.SendInternalServerError(c, "Failed to delete vehicle", err.Error())
		return
	}

	utils.SendSuccess(c, "Vehicle deleted successfully", nil)
}

// ListVehicles godoc
// @Summary List vehicles
// @Description Get list of vehicles with pagination
// @Tags vehicles
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Param status query string false "Vehicle status" Enums(available,in_repair,sold,reserved)
// @Success 200 {object} utils.APIResponse{data=[]models.Vehicle}
// @Security BearerAuth
// @Router /api/vehicles [get]
func (h *VehicleHandler) ListVehicles(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	statusStr := c.Query("status")

	var status *models.VehicleStatus
	if statusStr != "" {
		vehicleStatus := models.VehicleStatus(statusStr)
		status = &vehicleStatus
	}

	vehicles, total, err := h.vehicleService.List(page, limit, status)
	if err != nil {
		utils.SendInternalServerError(c, "Failed to list vehicles", err.Error())
		return
	}

	meta := utils.CalculatePaginationMeta(page, limit, total)
	utils.SendSuccessWithMeta(c, "Vehicles retrieved successfully", vehicles, meta)
}

// GetAvailableVehicles godoc
// @Summary Get available vehicles
// @Description Get list of available vehicles
// @Tags vehicles
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} utils.APIResponse{data=[]models.Vehicle}
// @Security BearerAuth
// @Router /api/vehicles/available [get]
func (h *VehicleHandler) GetAvailableVehicles(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	vehicles, total, err := h.vehicleService.GetAvailableVehicles(page, limit)
	if err != nil {
		utils.SendInternalServerError(c, "Failed to get available vehicles", err.Error())
		return
	}

	meta := utils.CalculatePaginationMeta(page, limit, total)
	utils.SendSuccessWithMeta(c, "Available vehicles retrieved successfully", vehicles, meta)
}

// SetSellingPrice godoc
// @Summary Set vehicle selling price
// @Description Set selling price for an available vehicle
// @Tags vehicles
// @Accept json
// @Produce json
// @Param id path int true "Vehicle ID"
// @Param request body object{selling_price=float64} true "Selling price"
// @Success 200 {object} utils.APIResponse
// @Failure 400 {object} utils.APIResponse
// @Failure 404 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/vehicles/{id}/selling-price [patch]
func (h *VehicleHandler) SetSellingPrice(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.SendBadRequest(c, "Invalid vehicle ID", err.Error())
		return
	}

	var req struct {
		SellingPrice float64 `json:"selling_price" validate:"required,min=0"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendBadRequest(c, "Invalid request format", err.Error())
		return
	}

	err = h.vehicleService.SetSellingPrice(id, req.SellingPrice)
	if err != nil {
		if err.Error() == "vehicle not found" {
			utils.SendNotFound(c, "Vehicle not found")
			return
		}
		if err.Error() == "can only set selling price for available vehicles" {
			utils.SendBadRequest(c, "Invalid vehicle status", err.Error())
			return
		}
		utils.SendInternalServerError(c, "Failed to set selling price", err.Error())
		return
	}

	utils.SendSuccess(c, "Selling price updated successfully", nil)
}

// SearchVehicles godoc
// @Summary Search vehicles with advanced filters
// @Description Search vehicles by brand, model, year, color, odometer, etc.
// @Tags vehicles
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Param brand_id query int false "Filter by brand ID"
// @Param model query string false "Filter by model (partial match)"
// @Param year_min query int false "Minimum year"
// @Param year_max query int false "Maximum year"
// @Param color query string false "Filter by color"
// @Param odometer_min query int false "Minimum odometer"
// @Param odometer_max query int false "Maximum odometer"
// @Param price_min query float64 false "Minimum price"
// @Param price_max query float64 false "Maximum price"
// @Param status query string false "Filter by status"
// @Success 200 {object} utils.APIResponse{data=[]models.Vehicle}
// @Security BearerAuth
// @Router /api/vehicles/search [get]
func (h *VehicleHandler) SearchVehicles(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	// Parse search filters
	filters := models.VehicleSearchFilters{
		BrandID:     parseIntQuery(c, "brand_id"),
		Model:       c.Query("model"),
		YearMin:     parseIntQuery(c, "year_min"),
		YearMax:     parseIntQuery(c, "year_max"),
		Color:       c.Query("color"),
		OdometerMin: parseIntQuery(c, "odometer_min"),
		OdometerMax: parseIntQuery(c, "odometer_max"),
		PriceMin:    parseFloatQuery(c, "price_min"),
		PriceMax:    parseFloatQuery(c, "price_max"),
		Status:      c.Query("status"),
	}

	vehicles, total, err := h.vehicleService.SearchVehicles(page, limit, filters)
	if err != nil {
		utils.SendInternalServerError(c, "Failed to search vehicles", err.Error())
		return
	}

	meta := utils.CalculatePaginationMeta(page, limit, total)
	utils.SendSuccessWithMeta(c, "Vehicles search completed successfully", vehicles, meta)
}

// GetVehicleBrands godoc
// @Summary Get all vehicle brands for dropdown
// @Description Get all available vehicle brands for search filters
// @Tags vehicles
// @Produce json
// @Success 200 {object} utils.APIResponse{data=[]models.VehicleBrand}
// @Security BearerAuth
// @Router /api/vehicles/brands [get]
func (h *VehicleHandler) GetVehicleBrands(c *gin.Context) {
	brands, err := h.vehicleService.GetAllBrands()
	if err != nil {
		utils.SendInternalServerError(c, "Failed to retrieve vehicle brands", err.Error())
		return
	}

	utils.SendSuccess(c, "Vehicle brands retrieved successfully", brands)
}

// Helper functions for parsing query parameters
func parseIntQuery(c *gin.Context, key string) *int {
	if val := c.Query(key); val != "" {
		if parsed, err := strconv.Atoi(val); err == nil {
			return &parsed
		}
	}
	return nil
}

func parseFloatQuery(c *gin.Context, key string) *float64 {
	if val := c.Query(key); val != "" {
		if parsed, err := strconv.ParseFloat(val, 64); err == nil {
			return &parsed
		}
	}
	return nil
}
