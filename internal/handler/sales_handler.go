package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type SalesHandler struct {
	salesService service.SalesService
}

func NewSalesHandler(salesService service.SalesService) *SalesHandler {
	return &SalesHandler{
		salesService: salesService,
	}
}

// CreateSalesTransaction handles POST /api/sales/transactions
func (h *SalesHandler) CreateSalesTransaction(c *gin.Context) {
	var req models.SalesTransactionCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Validation failed", err.Error())
		return
	}

	// Get user ID from JWT token (salesperson)
	userID, exists := c.Get("user_id")
	if !exists {
		utils.SendError(c, http.StatusUnauthorized, "User not authenticated", "User ID not found in token")
		return
	}

	req.SalespersonID = userID.(int)

	salesTransaction, err := h.salesService.CreateTransaction(&req)
	if err != nil {
		if err.Error() == "vehicle not found" || err.Error() == "customer not found" {
			utils.SendError(c, http.StatusNotFound, "Resource not found", err.Error())
			return
		}
		if err.Error() == "vehicle not available for sale" {
			utils.SendError(c, http.StatusBadRequest, "Vehicle not available", err.Error())
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to create sales transaction", err.Error())
		return
	}

	utils.SendSuccess(c, "Sales transaction created successfully", gin.H{
		"data": salesTransaction,
	})
}

// ListSalesTransactions handles GET /api/sales/transactions
func (h *SalesHandler) ListSalesTransactions(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	status := c.Query("status")
	dateFrom := c.Query("date_from")
	dateTo := c.Query("date_to")
	customerIDStr := c.Query("customer_id")

	var customerID *int
	if customerIDStr != "" {
		if id, err := strconv.Atoi(customerIDStr); err == nil {
			customerID = &id
		}
	}

	transactions, total, err := h.salesService.ListTransactions(page, limit, status, dateFrom, dateTo, customerID)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get sales transactions", err.Error())
		return
	}

	// Calculate pagination info
	totalPages := (int(total) + limit - 1) / limit

	utils.SendSuccess(c, "Sales transactions retrieved successfully", gin.H{
		"data": transactions,
		"pagination": gin.H{
			"current_page": page,
			"per_page":     limit,
			"total":        total,
			"total_pages":  totalPages,
		},
	})
}

// GetSalesTransaction handles GET /api/sales/transactions/:id
func (h *SalesHandler) GetSalesTransaction(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid transaction ID", "Transaction ID must be a number")
		return
	}

	transaction, err := h.salesService.GetTransactionByID(id)
	if err != nil {
		if err.Error() == "sales transaction not found" {
			utils.SendError(c, http.StatusNotFound, "Transaction not found", "Sales transaction with this ID does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to get sales transaction", err.Error())
		return
	}

	utils.SendSuccess(c, "Sales transaction retrieved successfully", gin.H{
		"data": transaction,
	})
}

// UpdateSalesTransaction handles PUT /api/sales/transactions/:id
func (h *SalesHandler) UpdateSalesTransaction(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid transaction ID", "Transaction ID must be a number")
		return
	}

	var req models.SalesTransactionUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Validation failed", err.Error())
		return
	}

	transaction, err := h.salesService.UpdateTransaction(id, &req)
	if err != nil {
		if err.Error() == "sales transaction not found" {
			utils.SendError(c, http.StatusNotFound, "Transaction not found", "Sales transaction with this ID does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to update sales transaction", err.Error())
		return
	}

	utils.SendSuccess(c, "Sales transaction updated successfully", gin.H{
		"data": transaction,
	})
}

// DeleteSalesTransaction handles DELETE /api/sales/transactions/:id
func (h *SalesHandler) DeleteSalesTransaction(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid transaction ID", "Transaction ID must be a number")
		return
	}

	err = h.salesService.DeleteTransaction(id)
	if err != nil {
		if err.Error() == "sales transaction not found" {
			utils.SendError(c, http.StatusNotFound, "Transaction not found", "Sales transaction with this ID does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to delete sales transaction", err.Error())
		return
	}

	utils.SendSuccess(c, "Sales transaction deleted successfully", nil)
}

// GetAvailableVehicles handles GET /api/sales/vehicles/available
func (h *SalesHandler) GetAvailableVehicles(c *gin.Context) {
	search := c.Query("search")
	brand := c.Query("brand")
	yearFromStr := c.Query("year_from")
	yearToStr := c.Query("year_to")
	sortBy := c.DefaultQuery("sort_by", "created_at")
	status := c.DefaultQuery("status", "available")

	var yearFrom, yearTo *int
	if yearFromStr != "" {
		if year, err := strconv.Atoi(yearFromStr); err == nil {
			yearFrom = &year
		}
	}
	if yearToStr != "" {
		if year, err := strconv.Atoi(yearToStr); err == nil {
			yearTo = &year
		}
	}

	vehicles, err := h.salesService.GetAvailableVehicles(search, brand, yearFrom, yearTo, sortBy, status)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get available vehicles", err.Error())
		return
	}

	utils.SendSuccess(c, "Available vehicles retrieved successfully", gin.H{
		"data": vehicles,
	})
}
