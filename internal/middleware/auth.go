package middleware

import (
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"

	"github.com/hafizd-kurniawan/pos-baru/internal/config"
	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type JWTClaims struct {
	UserID   int    `json:"user_id"`
	Username string `json:"username"`
	RoleID   int    `json:"role_id"`
	RoleName string `json:"role_name"`
	jwt.RegisteredClaims
}

type JWTMiddleware struct {
	config *config.Config
}

func NewJWTMiddleware(cfg *config.Config) *JWTMiddleware {
	return &JWTMiddleware{
		config: cfg,
	}
}

// GenerateToken generates a JWT token for a user
func (j *JWTMiddleware) GenerateToken(user *models.User) (string, error) {
	claims := JWTClaims{
		UserID:   user.ID,
		Username: user.Username,
		RoleID:   user.RoleID,
		RoleName: user.Role.Name,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(j.config.JWT.Secret))
}

// AuthMiddleware validates JWT tokens
func (j *JWTMiddleware) AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			utils.SendUnauthorized(c, "Authorization header required")
			c.Abort()
			return
		}

		// Check if the header starts with "Bearer "
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			utils.SendUnauthorized(c, "Invalid authorization header format")
			c.Abort()
			return
		}

		// Parse and validate the token
		token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
			// Validate the signing method
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}
			return []byte(j.config.JWT.Secret), nil
		})

		if err != nil {
			utils.SendUnauthorized(c, "Invalid token")
			c.Abort()
			return
		}

		claims, ok := token.Claims.(*JWTClaims)
		if !ok || !token.Valid {
			utils.SendUnauthorized(c, "Invalid token claims")
			c.Abort()
			return
		}

		// Set user information in context
		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("role_id", claims.RoleID)
		c.Set("role_name", claims.RoleName)

		c.Next()
	}
}

// RequireRole middleware to check if user has required role
func (j *JWTMiddleware) RequireRole(allowedRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		roleName, exists := c.Get("role_name")
		if !exists {
			utils.SendForbidden(c, "Role information not found")
			c.Abort()
			return
		}

		userRole := roleName.(string)
		for _, role := range allowedRoles {
			if userRole == role {
				c.Next()
				return
			}
		}

		utils.SendForbidden(c, "Insufficient permissions")
		c.Abort()
	}
}

// RequireAdmin middleware for admin-only endpoints
func (j *JWTMiddleware) RequireAdmin() gin.HandlerFunc {
	return j.RequireRole("admin")
}

// RequireCashierOrAdmin middleware for cashier and admin endpoints
func (j *JWTMiddleware) RequireCashierOrAdmin() gin.HandlerFunc {
	return j.RequireRole("admin", "kasir")
}

// RequireMechanicOrAdmin middleware for mechanic and admin endpoints
func (j *JWTMiddleware) RequireMechanicOrAdmin() gin.HandlerFunc {
	return j.RequireRole("admin", "mekanik")
}

// GetUserFromContext extracts user information from context
func GetUserFromContext(c *gin.Context) (int, string, int, string, error) {
	userID, exists := c.Get("user_id")
	if !exists {
		return 0, "", 0, "", gin.Error{Err: jwt.ErrTokenNotValidYet, Type: gin.ErrorTypePublic}
	}

	username, exists := c.Get("username")
	if !exists {
		return 0, "", 0, "", gin.Error{Err: jwt.ErrTokenNotValidYet, Type: gin.ErrorTypePublic}
	}

	roleID, exists := c.Get("role_id")
	if !exists {
		return 0, "", 0, "", gin.Error{Err: jwt.ErrTokenNotValidYet, Type: gin.ErrorTypePublic}
	}

	roleName, exists := c.Get("role_name")
	if !exists {
		return 0, "", 0, "", gin.Error{Err: jwt.ErrTokenNotValidYet, Type: gin.ErrorTypePublic}
	}

	return userID.(int), username.(string), roleID.(int), roleName.(string), nil
}