package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"github.com/hafizd-kurniawan/pos-baru/internal/config"
	"github.com/hafizd-kurniawan/pos-baru/internal/handler"
	"github.com/hafizd-kurniawan/pos-baru/internal/middleware"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
	"github.com/hafizd-kurniawan/pos-baru/internal/service"
	"github.com/hafizd-kurniawan/pos-baru/pkg/database"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatal("Failed to load configuration:", err)
	}

	// Connect to database
	db, err := database.NewConnection(cfg)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	// Initialize repositories
	userRepo := repository.NewUserRepository(db)
	vehicleRepo := repository.NewVehicleRepository(db)
	customerRepo := repository.NewCustomerRepository(db)
	// sparePartRepo := repository.NewSparePartRepository(db) // TODO: Add spare part handlers

	// Initialize JWT middleware
	jwtMiddleware := middleware.NewJWTMiddleware(cfg)

	// Initialize services
	authService := service.NewAuthService(userRepo, jwtMiddleware)
	vehicleService := service.NewVehicleService(vehicleRepo)
	customerService := service.NewCustomerService(customerRepo)

	// Initialize handlers
	authHandler := handler.NewAuthHandler(authService)
	vehicleHandler := handler.NewVehicleHandler(vehicleService)
	customerHandler := handler.NewCustomerHandler(customerService)

	// Setup router
	router := setupRouter(cfg, jwtMiddleware, authHandler, vehicleHandler, customerHandler)

	// Start server
	log.Printf("Starting server on port %s", cfg.Server.Port)
	if err := router.Run(":" + cfg.Server.Port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func setupRouter(cfg *config.Config, jwtMiddleware *middleware.JWTMiddleware, authHandler *handler.AuthHandler, vehicleHandler *handler.VehicleHandler, customerHandler *handler.CustomerHandler) *gin.Engine {
	// Set gin mode
	if cfg.App.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Create router
	router := gin.New()

	// Global middleware
	router.Use(middleware.LoggerMiddleware())
	router.Use(middleware.ErrorHandler())
	router.Use(middleware.CORS())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		utils.SendSuccess(c, "Service is healthy", gin.H{
			"status": "ok",
			"service": "POS Showroom API",
			"version": "1.0.0",
		})
	})

	// API routes
	api := router.Group("/api")
	{
		// Auth routes (public)
		auth := api.Group("/auth")
		{
			auth.POST("/login", authHandler.Login)
		}

		// Protected routes
		protected := api.Group("/")
		protected.Use(jwtMiddleware.AuthMiddleware())
		{
			// Auth protected routes
			authProtected := protected.Group("/auth")
			{
				authProtected.GET("/profile", authHandler.GetProfile)
				authProtected.POST("/register", jwtMiddleware.RequireAdmin(), authHandler.Register)
			}

			// Vehicle routes
			vehicles := protected.Group("/vehicles")
			{
				vehicles.GET("", vehicleHandler.ListVehicles)
				vehicles.GET("/available", vehicleHandler.GetAvailableVehicles)
				vehicles.GET("/:id", vehicleHandler.GetVehicle)
				vehicles.POST("", jwtMiddleware.RequireCashierOrAdmin(), vehicleHandler.CreateVehicle)
				vehicles.PUT("/:id", jwtMiddleware.RequireCashierOrAdmin(), vehicleHandler.UpdateVehicle)
				vehicles.DELETE("/:id", jwtMiddleware.RequireAdmin(), vehicleHandler.DeleteVehicle)
				vehicles.PATCH("/:id/selling-price", jwtMiddleware.RequireAdmin(), vehicleHandler.SetSellingPrice)
			}

			// Customer routes
			customers := protected.Group("/customers")
			{
				customers.GET("", customerHandler.ListCustomers)
				customers.GET("/:id", customerHandler.GetCustomer)
				customers.GET("/phone/:phone", customerHandler.GetCustomerByPhone)
				customers.GET("/email/:email", customerHandler.GetCustomerByEmail)
				customers.POST("", jwtMiddleware.RequireCashierOrAdmin(), customerHandler.CreateCustomer)
				customers.PUT("/:id", jwtMiddleware.RequireCashierOrAdmin(), customerHandler.UpdateCustomer)
				customers.DELETE("/:id", jwtMiddleware.RequireAdmin(), customerHandler.DeleteCustomer)
			}
		}
	}

	return router
}