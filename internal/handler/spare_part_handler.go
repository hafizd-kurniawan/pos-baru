package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type SparePartHandler struct {
	sparePartService service.SparePartService
}

func NewSparePartHandler(sparePartService service.SparePartService) *SparePartHandler {
	return &SparePartHandler{
		sparePartService: sparePartService,
	}
}

// ListSpareParts handles GET /api/spare-parts
func (h *SparePartHandler) ListSpareParts(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	search := c.Query("search")
	category := c.Query("category")

	// Parse active filter
	var isActive *bool
	if activeStr := c.Query("active"); activeStr != "" {
		if active, err := strconv.ParseBool(activeStr); err == nil {
			isActive = &active
		}
	}

	// Parse status filter for UI convenience
	statusFilter := c.Query("status")
	// Also support stock_filter parameter for backward compatibility
	if stockFilter := c.Query("stock_filter"); stockFilter != "" {
		statusFilter = stockFilter
	}

	if statusFilter != "" {
		switch statusFilter {
		case "available":
			active := true
			isActive = &active
		case "inactive":
			active := false
			isActive = &active
		case "low_stock", "out_of_stock", "in_stock":
			// These will be handled by service layer based on stock quantities
		}
	}

	spareParts, total, err := h.sparePartService.ListWithFilters(page, limit, search, category, isActive, statusFilter)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get spare parts", err.Error())
		return
	}

	// Calculate pagination info
	totalPages := (int(total) + limit - 1) / limit

	utils.SendSuccess(c, "Spare parts retrieved successfully", gin.H{
		"spare_parts": spareParts,
		"pagination": gin.H{
			"current_page": page,
			"per_page":     limit,
			"total":        total,
			"total_pages":  totalPages,
		},
	})
}

// GetSparePart handles GET /api/spare-parts/:id
func (h *SparePartHandler) GetSparePart(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid spare part ID", "Spare part ID must be a number")
		return
	}

	sparePart, err := h.sparePartService.GetByID(id)
	if err != nil {
		if err.Error() == "spare part not found" {
			utils.SendError(c, http.StatusNotFound, "Spare part not found", "Spare part with this ID does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to get spare part", err.Error())
		return
	}

	utils.SendSuccess(c, "Spare part retrieved successfully", gin.H{
		"spare_part": sparePart,
	})
}

// GetSparePartByCode handles GET /api/spare-parts/code/:code
func (h *SparePartHandler) GetSparePartByCode(c *gin.Context) {
	code := c.Param("code")
	if code == "" {
		utils.SendError(c, http.StatusBadRequest, "Invalid spare part code", "Spare part code is required")
		return
	}

	sparePart, err := h.sparePartService.GetByCode(code)
	if err != nil {
		if err.Error() == "spare part not found" {
			utils.SendError(c, http.StatusNotFound, "Spare part not found", "Spare part with this code does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to get spare part", err.Error())
		return
	}

	utils.SendSuccess(c, "Spare part retrieved successfully", gin.H{
		"spare_part": sparePart,
	})
}

// CreateSparePart handles POST /api/spare-parts
func (h *SparePartHandler) CreateSparePart(c *gin.Context) {
	var req models.SparePartCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Validation failed", err.Error())
		return
	}

	sparePart, err := h.sparePartService.Create(&req)
	if err != nil {
		if err.Error() == "spare part with this code already exists" {
			utils.SendError(c, http.StatusConflict, "Spare part already exists", err.Error())
			return
		}
		if err.Error() == "selling price cannot be less than purchase price" {
			utils.SendError(c, http.StatusBadRequest, "Invalid pricing", err.Error())
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to create spare part", err.Error())
		return
	}

	utils.SendSuccess(c, "Spare part created successfully", gin.H{
		"spare_part": sparePart,
	})
}

// UpdateSparePart handles PUT /api/spare-parts/:id
func (h *SparePartHandler) UpdateSparePart(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid spare part ID", "Spare part ID must be a number")
		return
	}

	var req models.SparePartUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Validation failed", err.Error())
		return
	}

	sparePart, err := h.sparePartService.Update(id, &req)
	if err != nil {
		if err.Error() == "spare part not found" {
			utils.SendError(c, http.StatusNotFound, "Spare part not found", "Spare part with this ID does not exist")
			return
		}
		if err.Error() == "selling price cannot be less than purchase price" {
			utils.SendError(c, http.StatusBadRequest, "Invalid pricing", err.Error())
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to update spare part", err.Error())
		return
	}

	utils.SendSuccess(c, "Spare part updated successfully", gin.H{
		"spare_part": sparePart,
	})
}

// DeleteSparePart handles DELETE /api/spare-parts/:id
func (h *SparePartHandler) DeleteSparePart(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid spare part ID", "Spare part ID must be a number")
		return
	}

	err = h.sparePartService.Delete(id)
	if err != nil {
		if err.Error() == "spare part not found" {
			utils.SendError(c, http.StatusNotFound, "Spare part not found", "Spare part with this ID does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to delete spare part", err.Error())
		return
	}

	utils.SendSuccess(c, "Spare part deleted successfully", nil)
}

// UpdateStock handles PATCH /api/spare-parts/:id/stock
func (h *SparePartHandler) UpdateStock(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid spare part ID", "Spare part ID must be a number")
		return
	}

	var req struct {
		Quantity  int    `json:"quantity" validate:"required,min=1"`
		Operation string `json:"operation" validate:"required,oneof=add subtract"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Validation failed", err.Error())
		return
	}

	err = h.sparePartService.UpdateStock(id, req.Quantity, req.Operation)
	if err != nil {
		if err.Error() == "spare part not found" {
			utils.SendError(c, http.StatusNotFound, "Spare part not found", "Spare part with this ID does not exist")
			return
		}
		if err.Error() == "insufficient stock" {
			utils.SendError(c, http.StatusBadRequest, "Insufficient stock", "Not enough stock available for this operation")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to update stock", err.Error())
		return
	}

	utils.SendSuccess(c, "Stock updated successfully", nil)
}

// GetLowStockItems handles GET /api/spare-parts/low-stock
func (h *SparePartHandler) GetLowStockItems(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	spareParts, total, err := h.sparePartService.GetLowStockItems(page, limit)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get low stock items", err.Error())
		return
	}

	// Calculate pagination info
	totalPages := (int(total) + limit - 1) / limit

	utils.SendSuccess(c, "Low stock items retrieved successfully", gin.H{
		"low_stock_items": spareParts,
		"pagination": gin.H{
			"current_page": page,
			"per_page":     limit,
			"total":        total,
			"total_pages":  totalPages,
		},
	})
}

// CheckStockAvailability handles GET /api/spare-parts/:id/stock-check?quantity=N
func (h *SparePartHandler) CheckStockAvailability(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid spare part ID", "Spare part ID must be a number")
		return
	}

	quantityParam := c.Query("quantity")
	if quantityParam == "" {
		utils.SendError(c, http.StatusBadRequest, "Missing quantity parameter", "Quantity is required")
		return
	}

	quantity, err := strconv.Atoi(quantityParam)
	if err != nil || quantity <= 0 {
		utils.SendError(c, http.StatusBadRequest, "Invalid quantity", "Quantity must be a positive number")
		return
	}

	available, err := h.sparePartService.CheckStockAvailability(id, quantity)
	if err != nil {
		if err.Error() == "spare part not found or inactive" {
			utils.SendError(c, http.StatusNotFound, "Spare part not found", "Spare part with this ID does not exist or is inactive")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to check stock availability", err.Error())
		return
	}

	utils.SendSuccess(c, "Stock availability checked successfully", gin.H{
		"available":          available,
		"requested_quantity": quantity,
	})
}

// BulkUpdateStock handles POST /api/spare-parts/bulk-stock-update
func (h *SparePartHandler) BulkUpdateStock(c *gin.Context) {
	var req struct {
		Updates []models.SparePartStockUpdate `json:"updates" validate:"required,min=1"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Validation failed", err.Error())
		return
	}

	err := h.sparePartService.BulkUpdateStock(req.Updates)
	if err != nil {
		if err.Error() == "no updates provided" {
			utils.SendError(c, http.StatusBadRequest, "No updates provided", "At least one update is required")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to process bulk stock update", err.Error())
		return
	}

	utils.SendSuccess(c, "Bulk stock update completed successfully", gin.H{
		"updates_processed": len(req.Updates),
	})
}

// GetCategories handles GET /api/spare-parts/categories
func (h *SparePartHandler) GetCategories(c *gin.Context) {
	categories, err := h.sparePartService.GetCategories()
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get categories", err.Error())
		return
	}

	utils.SendSuccess(c, "Categories retrieved successfully", gin.H{
		"categories": categories,
	})
}
