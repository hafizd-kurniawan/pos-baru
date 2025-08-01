package utils

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// APIResponse represents a standard API response
type APIResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
	Error   interface{} `json:"error,omitempty"`
	Meta    interface{} `json:"meta,omitempty"`
}

// PaginationMeta represents pagination metadata
type PaginationMeta struct {
	Page       int   `json:"page"`
	Limit      int   `json:"limit"`
	Total      int64 `json:"total"`
	TotalPages int   `json:"total_pages"`
}

// SendSuccess sends a successful response
func SendSuccess(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusOK, APIResponse{
		Success: true,
		Message: message,
		Data:    data,
	})
}

// SendSuccessWithMeta sends a successful response with metadata
func SendSuccessWithMeta(c *gin.Context, message string, data interface{}, meta interface{}) {
	c.JSON(http.StatusOK, APIResponse{
		Success: true,
		Message: message,
		Data:    data,
		Meta:    meta,
	})
}

// SendCreated sends a 201 created response
func SendCreated(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusCreated, APIResponse{
		Success: true,
		Message: message,
		Data:    data,
	})
}

// SendError sends an error response
func SendError(c *gin.Context, statusCode int, message string, err interface{}) {
	c.JSON(statusCode, APIResponse{
		Success: false,
		Message: message,
		Error:   err,
	})
}

// SendBadRequest sends a 400 bad request response
func SendBadRequest(c *gin.Context, message string, err interface{}) {
	SendError(c, http.StatusBadRequest, message, err)
}

// SendUnauthorized sends a 401 unauthorized response
func SendUnauthorized(c *gin.Context, message string) {
	SendError(c, http.StatusUnauthorized, message, nil)
}

// SendForbidden sends a 403 forbidden response
func SendForbidden(c *gin.Context, message string) {
	SendError(c, http.StatusForbidden, message, nil)
}

// SendNotFound sends a 404 not found response
func SendNotFound(c *gin.Context, message string) {
	SendError(c, http.StatusNotFound, message, nil)
}

// SendConflict sends a 409 conflict response
func SendConflict(c *gin.Context, message string, err interface{}) {
	SendError(c, http.StatusConflict, message, err)
}

// SendInternalServerError sends a 500 internal server error response
func SendInternalServerError(c *gin.Context, message string, err interface{}) {
	SendError(c, http.StatusInternalServerError, message, err)
}

// CalculatePaginationMeta calculates pagination metadata
func CalculatePaginationMeta(page, limit int, total int64) PaginationMeta {
	totalPages := int((total + int64(limit) - 1) / int64(limit))
	if totalPages < 1 {
		totalPages = 1
	}

	return PaginationMeta{
		Page:       page,
		Limit:      limit,
		Total:      total,
		TotalPages: totalPages,
	}
}