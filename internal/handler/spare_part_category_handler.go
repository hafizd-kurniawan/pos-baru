package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type SparePartCategoryHandler struct {
	service service.SparePartCategoryService
}

func NewSparePartCategoryHandler(service service.SparePartCategoryService) *SparePartCategoryHandler {
	return &SparePartCategoryHandler{
		service: service,
	}
}

func (h *SparePartCategoryHandler) Create(c *gin.Context) {
	var req models.SparePartCategoryCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request", err.Error())
		return
	}

	category, err := h.service.Create(&req)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to create category", err.Error())
		return
	}

	utils.SendSuccess(c, "Category created successfully", gin.H{
		"category": category,
	})
}

func (h *SparePartCategoryHandler) GetByID(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid category ID", "Category ID must be a number")
		return
	}

	category, err := h.service.GetByID(id)
	if err != nil {
		if err.Error() == "spare part category not found" {
			utils.SendError(c, http.StatusNotFound, "Category not found", "Category with this ID does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to get category", err.Error())
		return
	}

	utils.SendSuccess(c, "Category retrieved successfully", gin.H{
		"category": category,
	})
}

func (h *SparePartCategoryHandler) Update(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid category ID", "Category ID must be a number")
		return
	}

	var req models.SparePartCategoryUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request", err.Error())
		return
	}

	category, err := h.service.Update(id, &req)
	if err != nil {
		if err.Error() == "spare part category not found" {
			utils.SendError(c, http.StatusNotFound, "Category not found", "Category with this ID does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to update category", err.Error())
		return
	}

	utils.SendSuccess(c, "Category updated successfully", gin.H{
		"category": category,
	})
}

func (h *SparePartCategoryHandler) Delete(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid category ID", "Category ID must be a number")
		return
	}

	err = h.service.Delete(id)
	if err != nil {
		if err.Error() == "spare part category not found" {
			utils.SendError(c, http.StatusNotFound, "Category not found", "Category with this ID does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to delete category", err.Error())
		return
	}

	utils.SendSuccess(c, "Category deleted successfully", nil)
}

func (h *SparePartCategoryHandler) List(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	var isActive *bool
	if activeStr := c.Query("active"); activeStr != "" {
		if active, err := strconv.ParseBool(activeStr); err == nil {
			isActive = &active
		}
	}

	categories, total, err := h.service.List(page, limit, isActive)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get categories", err.Error())
		return
	}

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
