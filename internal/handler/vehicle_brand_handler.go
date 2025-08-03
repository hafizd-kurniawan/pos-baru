package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type VehicleBrandHandler struct {
	brandService service.VehicleBrandService
}

func NewVehicleBrandHandler(brandService service.VehicleBrandService) *VehicleBrandHandler {
	return &VehicleBrandHandler{
		brandService: brandService,
	}
}

// CreateVehicleBrand godoc
// @Summary Create vehicle brand
// @Description Create a new vehicle brand
// @Tags vehicle-brands
// @Accept json
// @Produce json
// @Param request body models.VehicleBrandCreateRequest true "Vehicle brand data"
// @Success 201 {object} utils.APIResponse{data=models.VehicleBrand}
// @Failure 400 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/vehicle-brands [post]
func (h *VehicleBrandHandler) CreateVehicleBrand(c *gin.Context) {
	var req models.VehicleBrandCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendBadRequest(c, "Invalid request format", err.Error())
		return
	}

	brand, err := h.brandService.Create(&req)
	if err != nil {
		utils.SendInternalServerError(c, "Failed to create vehicle brand", err.Error())
		return
	}

	utils.SendCreated(c, "Vehicle brand created successfully", brand)
}

// ListVehicleBrands godoc
// @Summary List vehicle brands
// @Description Get paginated list of vehicle brands
// @Tags vehicle-brands
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Param type_id query int false "Filter by vehicle type ID"
// @Success 200 {object} utils.PaginatedAPIResponse{data=[]models.VehicleBrand}
// @Security BearerAuth
// @Router /api/vehicle-brands [get]
func (h *VehicleBrandHandler) ListVehicleBrands(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	typeIDStr := c.Query("type_id")

	if typeIDStr != "" {
		typeID, err := strconv.Atoi(typeIDStr)
		if err != nil {
			utils.SendBadRequest(c, "Invalid type_id parameter", err.Error())
			return
		}

		brands, err := h.brandService.GetByTypeID(typeID)
		if err != nil {
			utils.SendInternalServerError(c, "Failed to get vehicle brands", err.Error())
			return
		}

		utils.SendSuccess(c, "Vehicle brands retrieved successfully", brands)
		return
	}

	brands, total, err := h.brandService.List(page, limit)
	if err != nil {
		utils.SendInternalServerError(c, "Failed to get vehicle brands", err.Error())
		return
	}

	// Create pagination metadata
	totalPages := int((total + int64(limit) - 1) / int64(limit))
	meta := utils.PaginationMeta{
		Page:       page,
		Limit:      limit,
		Total:      total,
		TotalPages: totalPages,
	}

	utils.SendSuccessWithMeta(c, "Vehicle brands retrieved successfully", brands, meta)
}

// GetVehicleBrand godoc
// @Summary Get vehicle brand by ID
// @Description Get vehicle brand details by ID
// @Tags vehicle-brands
// @Produce json
// @Param id path int true "Vehicle Brand ID"
// @Success 200 {object} utils.APIResponse{data=models.VehicleBrand}
// @Failure 404 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/vehicle-brands/{id} [get]
func (h *VehicleBrandHandler) GetVehicleBrand(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.SendBadRequest(c, "Invalid vehicle brand ID", err.Error())
		return
	}

	brand, err := h.brandService.GetByID(id)
	if err != nil {
		utils.SendNotFound(c, "Vehicle brand not found")
		return
	}

	utils.SendSuccess(c, "Vehicle brand retrieved successfully", brand)
}

// UpdateVehicleBrand godoc
// @Summary Update vehicle brand
// @Description Update vehicle brand information
// @Tags vehicle-brands
// @Accept json
// @Produce json
// @Param id path int true "Vehicle Brand ID"
// @Param request body models.VehicleBrandUpdateRequest true "Vehicle brand update data"
// @Success 200 {object} utils.APIResponse{data=models.VehicleBrand}
// @Failure 400 {object} utils.APIResponse
// @Failure 404 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/vehicle-brands/{id} [put]
func (h *VehicleBrandHandler) UpdateVehicleBrand(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.SendBadRequest(c, "Invalid vehicle brand ID", err.Error())
		return
	}

	var req models.VehicleBrandUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendBadRequest(c, "Invalid request format", err.Error())
		return
	}

	brand, err := h.brandService.Update(id, &req)
	if err != nil {
		if err.Error() == "vehicle brand not found" {
			utils.SendNotFound(c, "Vehicle brand not found")
			return
		}
		utils.SendInternalServerError(c, "Failed to update vehicle brand", err.Error())
		return
	}

	utils.SendSuccess(c, "Vehicle brand updated successfully", brand)
}

// DeleteVehicleBrand godoc
// @Summary Delete vehicle brand
// @Description Delete vehicle brand record
// @Tags vehicle-brands
// @Param id path int true "Vehicle Brand ID"
// @Success 200 {object} utils.APIResponse
// @Failure 400 {object} utils.APIResponse
// @Failure 404 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/vehicle-brands/{id} [delete]
func (h *VehicleBrandHandler) DeleteVehicleBrand(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.SendBadRequest(c, "Invalid vehicle brand ID", err.Error())
		return
	}

	err = h.brandService.Delete(id)
	if err != nil {
		if err.Error() == "vehicle brand not found" {
			utils.SendNotFound(c, "Vehicle brand not found")
			return
		}
		utils.SendInternalServerError(c, "Failed to delete vehicle brand", err.Error())
		return
	}

	utils.SendSuccess(c, "Vehicle brand deleted successfully", nil)
}
