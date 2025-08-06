package handler

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type RepairHandler struct {
	repairService service.RepairService
}

func NewRepairHandler(repairService service.RepairService) *RepairHandler {
	return &RepairHandler{
		repairService: repairService,
	}
}

// CreateRepairOrder creates a new repair order
// @Summary Create repair order
// @Description Create a new repair order for vehicle maintenance
// @Tags repairs
// @Accept json
// @Produce json
// @Param request body models.RepairOrderCreateRequest true "Repair order data"
// @Success 201 {object} utils.Response{data=models.RepairOrder}
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /repairs [post]
func (h *RepairHandler) CreateRepairOrder(c *gin.Context) {
	var req models.RepairOrderCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request data", err.Error())
		return
	}

	// Get assigned_by from JWT context
	assignedBy, exists := c.Get("user_id")
	if !exists {
		utils.SendError(c, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	repair, err := h.repairService.CreateRepairOrder(&req, assignedBy.(int))
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to create repair order", err.Error())
		return
	}

	utils.SendSuccess(c, "Repair order created successfully", repair)
}

// GetRepairOrder gets repair order by ID
// @Summary Get repair order
// @Description Get repair order details by ID
// @Tags repairs
// @Accept json
// @Produce json
// @Param id path int true "Repair Order ID"
// @Success 200 {object} utils.Response{data=models.RepairOrder}
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /repairs/{id} [get]
func (h *RepairHandler) GetRepairOrder(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid repair order ID", err.Error())
		return
	}

	repair, err := h.repairService.GetRepairOrder(id)
	if err != nil {
		utils.SendError(c, http.StatusNotFound, "Repair order not found", err.Error())
		return
	}

	utils.SendSuccess(c, "Repair order retrieved successfully", repair)
}

// GetRepairOrderByCode gets repair order by code
// @Summary Get repair order by code
// @Description Get repair order details by code
// @Tags repairs
// @Accept json
// @Produce json
// @Param code path string true "Repair Order Code"
// @Success 200 {object} utils.Response{data=models.RepairOrder}
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /repairs/code/{code} [get]
func (h *RepairHandler) GetRepairOrderByCode(c *gin.Context) {
	code := c.Param("code")
	if code == "" {
		utils.SendError(c, http.StatusBadRequest, "Repair order code is required", nil)
		return
	}

	repair, err := h.repairService.GetRepairOrderByCode(code)
	if err != nil {
		utils.SendError(c, http.StatusNotFound, "Repair order not found", err.Error())
		return
	}

	utils.SendSuccess(c, "Repair order retrieved successfully", repair)
}

// ListRepairOrders lists repair orders with filtering
// @Summary List repair orders
// @Description Get paginated list of repair orders with optional filtering
// @Tags repairs
// @Accept json
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Param status query string false "Filter by status"
// @Param mechanic_id query int false "Filter by mechanic ID"
// @Param vehicle_id query int false "Filter by vehicle ID"
// @Param date_from query string false "Filter from date (YYYY-MM-DD)"
// @Param date_to query string false "Filter to date (YYYY-MM-DD)"
// @Success 200 {object} utils.Response{data=utils.PaginatedResponse{items=[]models.RepairOrder}}
// @Failure 500 {object} utils.Response
// @Router /repairs [get]
func (h *RepairHandler) ListRepairOrders(c *gin.Context) {
	// Parse pagination parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	// Parse filter parameters
	var filter models.RepairOrderFilter
	if err := c.ShouldBindQuery(&filter); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid filter parameters", err.Error())
		return
	}

	repairs, total, err := h.repairService.ListRepairOrders(filter, page, limit)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to retrieve repair orders", err.Error())
		return
	}

	// Calculate pagination info
	totalPages := (total + limit - 1) / limit

	utils.SendSuccess(c, "Repair orders retrieved successfully", gin.H{
		"repairs": repairs,
		"pagination": gin.H{
			"current_page": page,
			"per_page":     limit,
			"total":        total,
			"total_pages":  totalPages,
		},
	})
}

// UpdateRepairOrder updates repair order details
// @Summary Update repair order
// @Description Update repair order basic information
// @Tags repairs
// @Accept json
// @Produce json
// @Param id path int true "Repair Order ID"
// @Param request body models.RepairOrderUpdateRequest true "Update data"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /repairs/{id} [put]
func (h *RepairHandler) UpdateRepairOrder(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid repair order ID", err.Error())
		return
	}

	var req models.RepairOrderUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request data", err.Error())
		return
	}

	err = h.repairService.UpdateRepairOrder(id, &req)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to update repair order", err.Error())
		return
	}

	utils.SendSuccess(c, "Repair order updated successfully", nil)
}

// UpdateRepairProgress updates repair progress and status
// @Summary Update repair progress
// @Description Update repair progress, status and add spare parts
// @Tags repairs
// @Accept json
// @Produce json
// @Param id path int true "Repair Order ID"
// @Param request body models.RepairProgressUpdateRequest true "Progress data"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /repairs/{id}/progress [patch]
func (h *RepairHandler) UpdateRepairProgress(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid repair order ID", err.Error())
		return
	}

	var req models.RepairProgressUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request data", err.Error())
		return
	}

	// Debug logging
	fmt.Printf("UpdateRepairProgress: ID=%d, Status=%s, ActualCost=%v, Notes=%v\n",
		id, req.Status, req.ActualCost, req.Notes)

	err = h.repairService.UpdateRepairProgress(id, &req)
	if err != nil {
		fmt.Printf("UpdateRepairProgress error: %v\n", err)
		utils.SendError(c, http.StatusInternalServerError, "Failed to update repair progress", err.Error())
		return
	}

	// Get updated repair order to return to client
	updatedRepair, err := h.repairService.GetRepairOrder(id)
	if err != nil {
		fmt.Printf("GetRepairOrder error after update: %v\n", err)
		utils.SendError(c, http.StatusInternalServerError, "Failed to get updated repair order", err.Error())
		return
	}

	fmt.Printf("UpdateRepairProgress success: returning repair with ID=%d, Status=%s\n",
		updatedRepair.ID, updatedRepair.Status)
	utils.SendSuccess(c, "Repair progress updated successfully", updatedRepair)
}

// DeleteRepairOrder deletes a repair order
// @Summary Delete repair order
// @Description Delete a repair order (only if pending or cancelled)
// @Tags repairs
// @Accept json
// @Produce json
// @Param id path int true "Repair Order ID"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /repairs/{id} [delete]
func (h *RepairHandler) DeleteRepairOrder(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid repair order ID", err.Error())
		return
	}

	err = h.repairService.DeleteRepairOrder(id)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to delete repair order", err.Error())
		return
	}

	utils.SendSuccess(c, "Repair order deleted successfully", nil)
}

// AddSparePartToRepair adds spare part to repair order
// @Summary Add spare part to repair
// @Description Add spare part usage to repair order
// @Tags repairs
// @Accept json
// @Produce json
// @Param id path int true "Repair Order ID"
// @Param request body models.RepairSparePartCreateRequest true "Spare part data"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /repairs/{id}/spare-parts [post]
func (h *RepairHandler) AddSparePartToRepair(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid repair order ID", err.Error())
		return
	}

	var req models.RepairSparePartCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request data", err.Error())
		return
	}

	err = h.repairService.AddSparePartToRepair(id, &req)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to add spare part to repair", err.Error())
		return
	}

	utils.SendSuccess(c, "Spare part added to repair successfully", nil)
}

// RemoveSparePartFromRepair removes spare part from repair order
// @Summary Remove spare part from repair
// @Description Remove spare part usage from repair order
// @Tags repairs
// @Accept json
// @Produce json
// @Param id path int true "Repair Order ID"
// @Param spare_part_id path int true "Spare Part ID"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /repairs/{id}/spare-parts/{spare_part_id} [delete]
func (h *RepairHandler) RemoveSparePartFromRepair(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid repair order ID", err.Error())
		return
	}

	sparePartID, err := strconv.Atoi(c.Param("spare_part_id"))
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid spare part ID", err.Error())
		return
	}

	err = h.repairService.RemoveSparePartFromRepair(id, sparePartID)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to remove spare part from repair", err.Error())
		return
	}

	utils.SendSuccess(c, "Spare part removed from repair successfully", nil)
}

// GetRepairSpareParts gets spare parts used in repair
// @Summary Get repair spare parts
// @Description Get list of spare parts used in repair order
// @Tags repairs
// @Accept json
// @Produce json
// @Param id path int true "Repair Order ID"
// @Success 200 {object} utils.Response{data=[]models.RepairSparePart}
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /repairs/{id}/spare-parts [get]
func (h *RepairHandler) GetRepairSpareParts(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid repair order ID", err.Error())
		return
	}

	spareParts, err := h.repairService.GetRepairSpareParts(id)
	if err != nil {
		utils.SendError(c, http.StatusNotFound, "Failed to get repair spare parts", err.Error())
		return
	}

	utils.SendSuccess(c, "Repair spare parts retrieved successfully", spareParts)
}

// GetRepairStats gets repair statistics
// @Summary Get repair statistics
// @Description Get repair statistics with optional filtering
// @Tags repairs
// @Accept json
// @Produce json
// @Param mechanic_id query int false "Filter by mechanic ID"
// @Param date_from query string false "Filter from date (YYYY-MM-DD)"
// @Param date_to query string false "Filter to date (YYYY-MM-DD)"
// @Success 200 {object} utils.Response{data=map[string]interface{}}
// @Failure 500 {object} utils.Response
// @Router /repairs/stats [get]
func (h *RepairHandler) GetRepairStats(c *gin.Context) {
	var mechanicID *int
	if mechanicIDStr := c.Query("mechanic_id"); mechanicIDStr != "" {
		if id, err := strconv.Atoi(mechanicIDStr); err == nil {
			mechanicID = &id
		}
	}

	var dateFrom, dateTo *time.Time
	if dateFromStr := c.Query("date_from"); dateFromStr != "" {
		if date, err := time.Parse("2006-01-02", dateFromStr); err == nil {
			dateFrom = &date
		}
	}
	if dateToStr := c.Query("date_to"); dateToStr != "" {
		if date, err := time.Parse("2006-01-02", dateToStr); err == nil {
			dateeTo := date.Add(24*time.Hour - time.Nanosecond) // End of day
			dateTo = &dateeTo
		}
	}

	stats, err := h.repairService.GetRepairStats(mechanicID, dateFrom, dateTo)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get repair statistics", err.Error())
		return
	}

	utils.SendSuccess(c, "Repair statistics retrieved successfully", stats)
}

// GetMechanicWorkload gets mechanic workload information
// @Summary Get mechanic workload
// @Description Get current workload information for mechanics
// @Tags repairs
// @Accept json
// @Produce json
// @Success 200 {object} utils.Response{data=[]map[string]interface{}}
// @Failure 500 {object} utils.Response
// @Router /repairs/mechanic-workload [get]
func (h *RepairHandler) GetMechanicWorkload(c *gin.Context) {
	workload, err := h.repairService.GetMechanicWorkload()
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get mechanic workload", err.Error())
		return
	}

	utils.SendSuccess(c, "Mechanic workload retrieved successfully", workload)
}

// GetVehiclesNeedingRepairOrders gets vehicles with in_repair status that don't have active repair orders
// @Summary Get vehicles needing repair orders
// @Description Get vehicles that are marked as in_repair but don't have active repair orders
// @Tags repairs
// @Accept json
// @Produce json
// @Success 200 {object} utils.Response{data=[]models.Vehicle}
// @Failure 500 {object} utils.Response
// @Router /repairs/vehicles-needing-orders [get]
func (h *RepairHandler) GetVehiclesNeedingRepairOrders(c *gin.Context) {
	vehicles, err := h.repairService.GetVehiclesNeedingRepairOrders()
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get vehicles needing repair orders", err.Error())
		return
	}

	utils.SendSuccess(c, "Vehicles needing repair orders retrieved successfully", vehicles)
}
