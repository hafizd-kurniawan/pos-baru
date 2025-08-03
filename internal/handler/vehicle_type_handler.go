package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type VehicleTypeHandler struct {
	vehicleTypeService service.VehicleTypeService
}

func NewVehicleTypeHandler(vehicleTypeService service.VehicleTypeService) *VehicleTypeHandler {
	return &VehicleTypeHandler{
		vehicleTypeService: vehicleTypeService,
	}
}

// CreateVehicleType godoc
// @Summary Create new vehicle type
// @Description Create a new vehicle type
// @Tags vehicle-types
// @Accept json
// @Produce json
// @Param request body models.VehicleTypeCreateRequest true "Vehicle type data"
// @Success 201 {object} utils.APIResponse{data=models.VehicleType}
// @Failure 400 {object} utils.APIResponse
// @Failure 409 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/vehicle-types [post]
func (h *VehicleTypeHandler) CreateVehicleType(c *gin.Context) {
	var req models.VehicleTypeCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendBadRequest(c, "Invalid request format", err.Error())
		return
	}

	vehicleType, err := h.vehicleTypeService.Create(&req)
	if err != nil {
		if err.Error() == "vehicle type name already exists" {
			utils.SendConflict(c, "Vehicle type already exists", err.Error())
			return
		}
		utils.SendInternalServerError(c, "Failed to create vehicle type", err.Error())
		return
	}

	utils.SendCreated(c, "Vehicle type created successfully", vehicleType)
}

// GetVehicleType godoc
// @Summary Get vehicle type by ID
// @Description Get vehicle type details by ID
// @Tags vehicle-types
// @Produce json
// @Param id path int true "Vehicle Type ID"
// @Success 200 {object} utils.APIResponse{data=models.VehicleType}
// @Failure 404 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/vehicle-types/{id} [get]
func (h *VehicleTypeHandler) GetVehicleType(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.SendBadRequest(c, "Invalid vehicle type ID", err.Error())
		return
	}

	vehicleType, err := h.vehicleTypeService.GetByID(id)
	if err != nil {
		utils.SendNotFound(c, "Vehicle type not found")
		return
	}

	utils.SendSuccess(c, "Vehicle type retrieved successfully", vehicleType)
}

// UpdateVehicleType godoc
// @Summary Update vehicle type
// @Description Update vehicle type information
// @Tags vehicle-types
// @Accept json
// @Produce json
// @Param id path int true "Vehicle Type ID"
// @Param request body models.VehicleTypeUpdateRequest true "Vehicle type update data"
// @Success 200 {object} utils.APIResponse{data=models.VehicleType}
// @Failure 400 {object} utils.APIResponse
// @Failure 404 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/vehicle-types/{id} [put]
func (h *VehicleTypeHandler) UpdateVehicleType(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.SendBadRequest(c, "Invalid vehicle type ID", err.Error())
		return
	}

	var req models.VehicleTypeUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendBadRequest(c, "Invalid request format", err.Error())
		return
	}

	vehicleType, err := h.vehicleTypeService.Update(id, &req)
	if err != nil {
		if err.Error() == "vehicle type not found" {
			utils.SendNotFound(c, "Vehicle type not found")
			return
		}
		if err.Error() == "vehicle type name already exists" {
			utils.SendConflict(c, "Vehicle type name already exists", err.Error())
			return
		}
		utils.SendInternalServerError(c, "Failed to update vehicle type", err.Error())
		return
	}

	utils.SendSuccess(c, "Vehicle type updated successfully", vehicleType)
}

// DeleteVehicleType godoc
// @Summary Delete vehicle type
// @Description Delete vehicle type record
// @Tags vehicle-types
// @Param id path int true "Vehicle Type ID"
// @Success 200 {object} utils.APIResponse
// @Failure 400 {object} utils.APIResponse
// @Failure 404 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/vehicle-types/{id} [delete]
func (h *VehicleTypeHandler) DeleteVehicleType(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.SendBadRequest(c, "Invalid vehicle type ID", err.Error())
		return
	}

	err = h.vehicleTypeService.Delete(id)
	if err != nil {
		if err.Error() == "vehicle type not found" {
			utils.SendNotFound(c, "Vehicle type not found")
			return
		}
		utils.SendInternalServerError(c, "Failed to delete vehicle type", err.Error())
		return
	}

	utils.SendSuccess(c, "Vehicle type deleted successfully", nil)
}

// ListVehicleTypes godoc
// @Summary List vehicle types
// @Description Get list of all vehicle types
// @Tags vehicle-types
// @Produce json
// @Success 200 {object} utils.APIResponse{data=[]models.VehicleType}
// @Security BearerAuth
// @Router /api/vehicle-types [get]
func (h *VehicleTypeHandler) ListVehicleTypes(c *gin.Context) {
	vehicleTypes, err := h.vehicleTypeService.List()
	if err != nil {
		utils.SendInternalServerError(c, "Failed to retrieve vehicle types", err.Error())
		return
	}

	utils.SendSuccess(c, "Vehicle types retrieved successfully", vehicleTypes)
}
