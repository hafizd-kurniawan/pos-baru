package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type CustomerHandler struct {
	customerService service.CustomerService
}

func NewCustomerHandler(customerService service.CustomerService) *CustomerHandler {
	return &CustomerHandler{
		customerService: customerService,
	}
}

// ListCustomers handles GET /api/customers
func (h *CustomerHandler) ListCustomers(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	customers, total, err := h.customerService.List(page, limit)
	if err != nil {
		utils.SendError(c, http.StatusInternalServerError, "Failed to get customers", err.Error())
		return
	}

	// Calculate pagination info
	totalPages := (int(total) + limit - 1) / limit
	
	utils.SendSuccess(c, "Customers retrieved successfully", gin.H{
		"customers": customers,
		"pagination": gin.H{
			"current_page": page,
			"per_page":     limit,
			"total":        total,
			"total_pages":  totalPages,
		},
	})
}

// GetCustomer handles GET /api/customers/:id
func (h *CustomerHandler) GetCustomer(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid customer ID", "Customer ID must be a number")
		return
	}

	customer, err := h.customerService.GetByID(id)
	if err != nil {
		if err.Error() == "customer not found" {
			utils.SendError(c, http.StatusNotFound, "Customer not found", "Customer with this ID does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to get customer", err.Error())
		return
	}

	utils.SendSuccess(c, "Customer retrieved successfully", gin.H{
		"customer": customer,
	})
}

// CreateCustomer handles POST /api/customers
func (h *CustomerHandler) CreateCustomer(c *gin.Context) {
	var req models.CustomerCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Validation failed", err.Error())
		return
	}

	customer, err := h.customerService.Create(&req)
	if err != nil {
		if err.Error() == "customer with this phone number already exists" || 
		   err.Error() == "customer with this email already exists" {
			utils.SendError(c, http.StatusConflict, "Customer already exists", err.Error())
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to create customer", err.Error())
		return
	}

	utils.SendSuccess(c, "Customer created successfully", gin.H{
		"customer": customer,
	})
}

// UpdateCustomer handles PUT /api/customers/:id
func (h *CustomerHandler) UpdateCustomer(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid customer ID", "Customer ID must be a number")
		return
	}

	var req models.CustomerUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(req); err != nil {
		utils.SendError(c, http.StatusBadRequest, "Validation failed", err.Error())
		return
	}

	customer, err := h.customerService.Update(id, &req)
	if err != nil {
		if err.Error() == "customer not found" {
			utils.SendError(c, http.StatusNotFound, "Customer not found", "Customer with this ID does not exist")
			return
		}
		if err.Error() == "another customer with this phone number already exists" || 
		   err.Error() == "another customer with this email already exists" {
			utils.SendError(c, http.StatusConflict, "Customer data conflict", err.Error())
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to update customer", err.Error())
		return
	}

	utils.SendSuccess(c, "Customer updated successfully", gin.H{
		"customer": customer,
	})
}

// DeleteCustomer handles DELETE /api/customers/:id
func (h *CustomerHandler) DeleteCustomer(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.SendError(c, http.StatusBadRequest, "Invalid customer ID", "Customer ID must be a number")
		return
	}

	err = h.customerService.Delete(id)
	if err != nil {
		if err.Error() == "customer not found" {
			utils.SendError(c, http.StatusNotFound, "Customer not found", "Customer with this ID does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to delete customer", err.Error())
		return
	}

	utils.SendSuccess(c, "Customer deleted successfully", nil)
}

// GetCustomerByPhone handles GET /api/customers/phone/:phone
func (h *CustomerHandler) GetCustomerByPhone(c *gin.Context) {
	phone := c.Param("phone")
	if phone == "" {
		utils.SendError(c, http.StatusBadRequest, "Invalid phone number", "Phone number is required")
		return
	}

	customer, err := h.customerService.GetByPhone(phone)
	if err != nil {
		if err.Error() == "customer not found" {
			utils.SendError(c, http.StatusNotFound, "Customer not found", "Customer with this phone number does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to get customer", err.Error())
		return
	}

	utils.SendSuccess(c, "Customer retrieved successfully", gin.H{
		"customer": customer,
	})
}

// GetCustomerByEmail handles GET /api/customers/email/:email
func (h *CustomerHandler) GetCustomerByEmail(c *gin.Context) {
	email := c.Param("email")
	if email == "" {
		utils.SendError(c, http.StatusBadRequest, "Invalid email", "Email is required")
		return
	}

	customer, err := h.customerService.GetByEmail(email)
	if err != nil {
		if err.Error() == "customer not found" {
			utils.SendError(c, http.StatusNotFound, "Customer not found", "Customer with this email does not exist")
			return
		}
		utils.SendError(c, http.StatusInternalServerError, "Failed to get customer", err.Error())
		return
	}

	utils.SendSuccess(c, "Customer retrieved successfully", gin.H{
		"customer": customer,
	})
}