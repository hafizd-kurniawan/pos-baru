package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type SupplierHandler struct {
	supplierService service.SupplierService
}

func NewSupplierHandler(supplierService service.SupplierService) *SupplierHandler {
	return &SupplierHandler{
		supplierService: supplierService,
	}
}

// CreateSupplier creates a new supplier
func (h *SupplierHandler) CreateSupplier(c *gin.Context) {
	var req models.SupplierCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid request body: "+err.Error())
		return
	}
	
	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Validation failed: "+err.Error())
		return
	}
	
	supplier, err := h.supplierService.CreateSupplier(&req)
	if err != nil {
		if err.Error() == "supplier with this phone number already exists" || 
		   err.Error() == "supplier with this email already exists" {
			utils.SendError(c, 409, "Conflict", err.Error())
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to create supplier: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Supplier created successfully", supplier)
}

// GetSupplier retrieves a supplier by ID
func (h *SupplierHandler) GetSupplier(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid supplier ID format")
		return
	}
	
	supplier, err := h.supplierService.GetSupplier(id)
	if err != nil {
		if err.Error() == "supplier not found" {
			utils.SendError(c, 404, "Not Found", "Supplier not found")
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to get supplier: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Supplier retrieved successfully", supplier)
}

// GetSupplierByPhone retrieves a supplier by phone number
func (h *SupplierHandler) GetSupplierByPhone(c *gin.Context) {
	phone := c.Param("phone")
	if phone == "" {
		utils.SendError(c, 400, "Bad Request", "Phone number is required")
		return
	}
	
	supplier, err := h.supplierService.GetSupplierByPhone(phone)
	if err != nil {
		if err.Error() == "supplier not found" {
			utils.SendError(c, 404, "Not Found", "Supplier not found")
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to get supplier: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Supplier retrieved successfully", supplier)
}

// GetSupplierByEmail retrieves a supplier by email
func (h *SupplierHandler) GetSupplierByEmail(c *gin.Context) {
	email := c.Param("email")
	if email == "" {
		utils.SendError(c, 400, "Bad Request", "Email is required")
		return
	}
	
	supplier, err := h.supplierService.GetSupplierByEmail(email)
	if err != nil {
		if err.Error() == "supplier not found" {
			utils.SendError(c, 404, "Not Found", "Supplier not found")
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to get supplier: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Supplier retrieved successfully", supplier)
}

// UpdateSupplier updates an existing supplier
func (h *SupplierHandler) UpdateSupplier(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid supplier ID format")
		return
	}
	
	var req models.SupplierUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid request body: "+err.Error())
		return
	}
	
	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.SendError(c, 400, "Bad Request", "Validation failed: "+err.Error())
		return
	}
	
	supplier, err := h.supplierService.UpdateSupplier(id, &req)
	if err != nil {
		if err.Error() == "supplier not found" {
			utils.SendError(c, 404, "Not Found", "Supplier not found")
			return
		}
		if err.Error() == "another supplier with this phone number already exists" || 
		   err.Error() == "another supplier with this email already exists" {
			utils.SendError(c, 409, "Conflict", err.Error())
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to update supplier: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Supplier updated successfully", supplier)
}

// DeleteSupplier deletes a supplier (soft delete)
func (h *SupplierHandler) DeleteSupplier(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.SendError(c, 400, "Bad Request", "Invalid supplier ID format")
		return
	}
	
	err = h.supplierService.DeleteSupplier(id)
	if err != nil {
		if err.Error() == "supplier not found" {
			utils.SendError(c, 404, "Not Found", "Supplier not found")
			return
		}
		utils.SendError(c, 500, "Internal Server Error", "Failed to delete supplier: "+err.Error())
		return
	}
	
	utils.SendSuccess(c, "Supplier deleted successfully", gin.H{
		"deleted_id": id,
	})
}

// ListSuppliers retrieves suppliers with pagination and filters
func (h *SupplierHandler) ListSuppliers(c *gin.Context) {
	// Parse query parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	search := c.Query("search")
	
	var isActive *bool
	if activeStr := c.Query("is_active"); activeStr != "" {
		active, err := strconv.ParseBool(activeStr)
		if err == nil {
			isActive = &active
		}
	}
	
	suppliers, total, err := h.supplierService.ListSuppliers(page, limit, search, isActive)
	if err != nil {
		utils.SendError(c, 500, "Internal Server Error", "Failed to list suppliers: "+err.Error())
		return
	}
	
	utils.SendSuccessWithMeta(c, "Suppliers retrieved successfully", suppliers, utils.CalculatePaginationMeta(page, limit, int64(total)))
}

// GetActiveSuppliers retrieves only active suppliers
func (h *SupplierHandler) GetActiveSuppliers(c *gin.Context) {
	// Parse query parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	search := c.Query("search")
	
	active := true
	suppliers, total, err := h.supplierService.ListSuppliers(page, limit, search, &active)
	if err != nil {
		utils.SendError(c, 500, "Internal Server Error", "Failed to list active suppliers: "+err.Error())
		return
	}
	
	utils.SendSuccessWithMeta(c, "Active suppliers retrieved successfully", suppliers, utils.CalculatePaginationMeta(page, limit, int64(total)))
}