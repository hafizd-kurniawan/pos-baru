package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type CategoryHandler struct {
	sparePartService service.SparePartService
}

func NewCategoryHandler(sparePartService service.SparePartService) *CategoryHandler {
	return &CategoryHandler{
		sparePartService: sparePartService,
	}
}

// GetCategories handles GET /api/categories
func (h *CategoryHandler) GetCategories(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	search := c.Query("search")

	categories, total, err := h.sparePartService.GetCategoriesWithPagination(page, limit, search)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get categories", err.Error())
		return
	}

	// Calculate pagination info
	totalPages := (int(total) + limit - 1) / limit

	utils.SendSuccess(c, "Categories retrieved successfully", gin.H{
		"categories": categories,
		"pagination": gin.H{
			"current_page": page,
			"per_page":     limit,
			"total":        total,
			"total_pages":  totalPages,
		},
	})
}

// CreateCategory handles POST /api/categories
func (h *CategoryHandler) CreateCategory(c *gin.Context) {
	var request struct {
		Name        string `json:"name" binding:"required"`
		Description string `json:"description"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid input", err.Error())
		return
	}

	err := h.sparePartService.CreateCategory(request.Name, request.Description)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to create category", err.Error())
		return
	}

	utils.SendSuccess(c, "Category created successfully", gin.H{
		"name":        request.Name,
		"description": request.Description,
	})
}

// UpdateCategory handles PUT /api/categories/:id
func (h *CategoryHandler) UpdateCategory(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid category ID", "Category ID must be a number")
		return
	}

	var request struct {
		Name        string `json:"name" binding:"required"`
		Description string `json:"description"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid input", err.Error())
		return
	}

	err = h.sparePartService.UpdateCategory(id, request.Name, request.Description)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to update category", err.Error())
		return
	}

	utils.SendSuccess(c, "Category updated successfully", gin.H{
		"id":          id,
		"name":        request.Name,
		"description": request.Description,
	})
}

// DeleteCategory handles DELETE /api/categories/:id
func (h *CategoryHandler) DeleteCategory(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid category ID", "Category ID must be a number")
		return
	}

	err = h.sparePartService.DeleteCategory(id)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to delete category", err.Error())
		return
	}

	utils.SendSuccess(c, "Category deleted successfully", nil)
}

// GetCategoryStats handles GET /api/categories/stats
func (h *CategoryHandler) GetCategoryStats(c *gin.Context) {
	// Get basic category statistics
	categories, _, err := h.sparePartService.GetCategoriesWithPagination(1, 1000, "")
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get category statistics", err.Error())
		return
	}

	// Calculate total parts per category
	totalCategories := len(categories)
	totalParts := 0
	for _, category := range categories {
		totalParts += category.SparePartCount
	}

	utils.SendSuccess(c, "Category statistics retrieved successfully", gin.H{
		"total_categories": totalCategories,
		"total_parts":      totalParts,
	})
}

// GetAllActiveCategories handles GET /api/categories/all
func (h *CategoryHandler) GetAllActiveCategories(c *gin.Context) {
	// Get all active categories for dropdown/select usage
	categories, err := h.sparePartService.GetCategories()
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get categories", err.Error())
		return
	}

	utils.SendSuccess(c, "Categories retrieved successfully", gin.H{
		"categories": categories,
	})
}
