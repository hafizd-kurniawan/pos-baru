package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type TransactionHandler struct {
	transactionService service.TransactionService
}

func NewTransactionHandler(transactionService service.TransactionService) *TransactionHandler {
	return &TransactionHandler{
		transactionService: transactionService,
	}
}

// CreatePurchaseTransaction handles POST /api/transactions/purchase
func (h *TransactionHandler) CreatePurchaseTransaction(c *gin.Context) {
	var req models.PurchaseTransactionCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Validation failed", err.Error())
		return
	}

	// Get user ID from JWT claims
	userID, exists := c.Get("user_id")
	if !exists {
		utils.SendError(c, http.StatusUnauthorized, "User not authenticated", "User ID not found in token")
		return
	}

	transaction, err := h.transactionService.CreatePurchaseTransaction(&req, userID.(int))
	if err != nil {
		if err.Error() == "vehicle not found" {
			utils.SendError(c, http.StatusNotFound, "Vehicle not found", "Vehicle with this ID does not exist")
			return
		}
		if err.Error() == "vehicle is already sold" {
			utils.SendError(c, http.StatusConflict, "Vehicle already sold", "This vehicle has already been sold")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to create purchase transaction", err.Error())
		return
	}

	utils.SendSuccess(c, "Purchase transaction created successfully", gin.H{
		"transaction": transaction,
	})
}

// CreateSalesTransaction handles POST /api/transactions/sales
func (h *TransactionHandler) CreateSalesTransaction(c *gin.Context) {
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

	// Get user ID from JWT claims
	userID, exists := c.Get("user_id")
	if !exists {
		utils.SendError(c, http.StatusUnauthorized, "User not authenticated", "User ID not found in token")
		return
	}

	transaction, err := h.transactionService.CreateSalesTransaction(&req, userID.(int))
	if err != nil {
		if err.Error() == "vehicle not found" {
			utils.SendError(c, http.StatusNotFound, "Vehicle not found", "Vehicle with this ID does not exist")
			return
		}
		if err.Error() == "customer not found" {
			utils.SendError(c, http.StatusNotFound, "Customer not found", "Customer with this ID does not exist")
			return
		}
		if err.Error() == "vehicle is not available for sale" {
			utils.SendError(c, http.StatusConflict, "Vehicle not available", "This vehicle is not available for sale")
			return
		}
		if err.Error()[:38] == "selling price cannot be less than HPP" {
			utils.SendError(c, http.StatusBadRequest, "Invalid selling price", err.Error())
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to create sales transaction", err.Error())
		return
	}

	utils.SendSuccess(c, "Sales transaction created successfully", gin.H{
		"transaction": transaction,
	})
}

// GetPurchaseTransaction handles GET /api/transactions/purchase/:id
func (h *TransactionHandler) GetPurchaseTransaction(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid transaction ID", "Transaction ID must be a number")
		return
	}

	transaction, err := h.transactionService.GetPurchaseTransactionByID(id)
	if err != nil {
		if err.Error() == "purchase transaction not found" {
			utils.SendError(c, http.StatusNotFound, "Transaction not found", "Purchase transaction with this ID does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to get purchase transaction", err.Error())
		return
	}

	utils.SendSuccess(c, "Purchase transaction retrieved successfully", gin.H{
		"transaction": transaction,
	})
}

// GetSalesTransaction handles GET /api/transactions/sales/:id
func (h *TransactionHandler) GetSalesTransaction(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid transaction ID", "Transaction ID must be a number")
		return
	}

	transaction, err := h.transactionService.GetSalesTransactionByID(id)
	if err != nil {
		if err.Error() == "sales transaction not found" {
			utils.SendError(c, http.StatusNotFound, "Transaction not found", "Sales transaction with this ID does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to get sales transaction", err.Error())
		return
	}

	utils.SendSuccess(c, "Sales transaction retrieved successfully", gin.H{
		"transaction": transaction,
	})
}

// ListPurchaseTransactions handles GET /api/transactions/purchase
func (h *TransactionHandler) ListPurchaseTransactions(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	// Parse date filters
	var dateFrom, dateTo *time.Time
	if dateFromStr := c.Query("date_from"); dateFromStr != "" {
		if parsed, err := time.Parse("2006-01-02", dateFromStr); err == nil {
			dateFrom = &parsed
		}
	}
	if dateToStr := c.Query("date_to"); dateToStr != "" {
		if parsed, err := time.Parse("2006-01-02", dateToStr); err == nil {
			dateTo = &parsed
		}
	}

	transactions, total, err := h.transactionService.ListPurchaseTransactions(page, limit, dateFrom, dateTo)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get purchase transactions", err.Error())
		return
	}

	// Calculate pagination info
	totalPages := (int(total) + limit - 1) / limit

	utils.SendSuccess(c, "Purchase transactions retrieved successfully", gin.H{
		"transactions": transactions,
		"pagination": gin.H{
			"current_page": page,
			"per_page":     limit,
			"total":        total,
			"total_pages":  totalPages,
		},
	})
}

// ListSalesTransactions handles GET /api/transactions/sales
func (h *TransactionHandler) ListSalesTransactions(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	// Parse date filters
	var dateFrom, dateTo *time.Time
	if dateFromStr := c.Query("date_from"); dateFromStr != "" {
		if parsed, err := time.Parse("2006-01-02", dateFromStr); err == nil {
			dateFrom = &parsed
		}
	}
	if dateToStr := c.Query("date_to"); dateToStr != "" {
		if parsed, err := time.Parse("2006-01-02", dateToStr); err == nil {
			dateTo = &parsed
		}
	}

	transactions, total, err := h.transactionService.ListSalesTransactions(page, limit, dateFrom, dateTo)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get sales transactions", err.Error())
		return
	}

	// Calculate pagination info
	totalPages := (int(total) + limit - 1) / limit

	utils.SendSuccess(c, "Sales transactions retrieved successfully", gin.H{
		"transactions": transactions,
		"pagination": gin.H{
			"current_page": page,
			"per_page":     limit,
			"total":        total,
			"total_pages":  totalPages,
		},
	})
}

// UpdatePurchasePaymentStatus handles PATCH /api/transactions/purchase/:id/payment
func (h *TransactionHandler) UpdatePurchasePaymentStatus(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid transaction ID", "Transaction ID must be a number")
		return
	}

	var req models.PaymentUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Validation failed", err.Error())
		return
	}

	err = h.transactionService.UpdatePurchasePaymentStatus(id, &req)
	if err != nil {
		if err.Error() == "purchase transaction not found" {
			utils.SendError(c, http.StatusNotFound, "Transaction not found", "Purchase transaction with this ID does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to update payment status", err.Error())
		return
	}

	utils.SendSuccess(c, "Purchase payment status updated successfully", nil)
}

// UpdateSalesPaymentStatus handles PATCH /api/transactions/sales/:id/payment
func (h *TransactionHandler) UpdateSalesPaymentStatus(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid transaction ID", "Transaction ID must be a number")
		return
	}

	var req models.PaymentUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Validation failed", err.Error())
		return
	}

	err = h.transactionService.UpdateSalesPaymentStatus(id, &req)
	if err != nil {
		if err.Error() == "sales transaction not found" {
			utils.SendError(c, http.StatusNotFound, "Transaction not found", "Sales transaction with this ID does not exist")
			return
		}
		if err.Error() == "down payment + remaining payment must equal selling price" {
			utils.SendError(c, http.StatusBadRequest, "Invalid payment amounts", err.Error())
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to update payment status", err.Error())
		return
	}

	utils.SendSuccess(c, "Sales payment status updated successfully", nil)
}