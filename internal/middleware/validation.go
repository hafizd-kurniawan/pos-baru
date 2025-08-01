package middleware

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"

	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

var validate *validator.Validate

func init() {
	validate = validator.New()
}

// ValidationMiddleware provides request validation
func ValidationMiddleware() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		c.Next()
	})
}

// ValidateJSON validates JSON request body
func ValidateJSON(obj interface{}) gin.HandlerFunc {
	return func(c *gin.Context) {
		if err := c.ShouldBindJSON(obj); err != nil {
			utils.SendBadRequest(c, "Invalid JSON format", err.Error())
			c.Abort()
			return
		}

		if err := validate.Struct(obj); err != nil {
			validationErrors := make(map[string]string)
			for _, err := range err.(validator.ValidationErrors) {
				validationErrors[err.Field()] = getValidationErrorMessage(err)
			}
			utils.SendBadRequest(c, "Validation failed", validationErrors)
			c.Abort()
			return
		}

		c.Set("validated_data", obj)
		c.Next()
	}
}

// CORS middleware for handling cross-origin requests
func CORS() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Credentials", "true")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Header("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE, PATCH")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})
}

// ErrorHandler middleware for handling panics and errors
func ErrorHandler() gin.HandlerFunc {
	return gin.RecoveryWithWriter(gin.DefaultWriter, func(c *gin.Context, recovered interface{}) {
		if err, ok := recovered.(string); ok {
			utils.SendInternalServerError(c, "Internal server error", err)
		} else {
			utils.SendInternalServerError(c, "Internal server error", "Unknown error occurred")
		}
		c.Abort()
	})
}

// LoggerMiddleware for request logging
func LoggerMiddleware() gin.HandlerFunc {
	return gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		return fmt.Sprintf("%s | %s | %s | %s | %d | %v\n",
			param.TimeStamp.Format("2006/01/02 - 15:04:05"),
			param.Method,
			param.Path,
			param.ClientIP,
			param.StatusCode,
			param.Latency,
		)
	})
}

// getValidationErrorMessage returns a user-friendly error message for validation errors
func getValidationErrorMessage(err validator.FieldError) string {
	switch err.Tag() {
	case "required":
		return "This field is required"
	case "email":
		return "Must be a valid email address"
	case "min":
		return "Must be at least " + err.Param() + " characters"
	case "max":
		return "Must be at most " + err.Param() + " characters"
	case "oneof":
		return "Must be one of: " + err.Param()
	default:
		return "Invalid value"
	}
}