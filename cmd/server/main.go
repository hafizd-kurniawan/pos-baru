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
	vehicleTypeRepo := repository.NewVehicleTypeRepository(db)
	customerRepo := repository.NewCustomerRepository(db)
	transactionRepo := repository.NewTransactionRepository(db)
	salesRepo := repository.NewSalesRepository(db.DB)
	sparePartRepo := repository.NewSparePartRepository(db)
	repairRepo := repository.NewRepairRepository(db)
	dashboardRepo := repository.NewDashboardRepository(db.DB)
	supplierRepo := repository.NewSupplierRepository(db.DB)

	// Initialize JWT middleware
	jwtMiddleware := middleware.NewJWTMiddleware(cfg)

	// Initialize services
	authService := service.NewAuthService(userRepo, jwtMiddleware)
	vehicleService := service.NewVehicleService(vehicleRepo)
	vehicleTypeService := service.NewVehicleTypeService(vehicleTypeRepo)
	customerService := service.NewCustomerService(customerRepo)
	transactionService := service.NewTransactionService(transactionRepo, vehicleRepo, customerRepo)
	salesService := service.NewSalesService(salesRepo, vehicleRepo, customerRepo)
	sparePartService := service.NewSparePartService(sparePartRepo)
	repairService := service.NewRepairService(repairRepo, vehicleRepo, userRepo, sparePartRepo)
	dashboardService := service.NewDashboardService(dashboardRepo)
	supplierService := service.NewSupplierService(supplierRepo)
	userService := service.NewUserService(userRepo)

	// Initialize handlers
	authHandler := handler.NewAuthHandler(authService)
	vehicleHandler := handler.NewVehicleHandler(vehicleService, repairService)
	vehicleTypeHandler := handler.NewVehicleTypeHandler(vehicleTypeService)
	customerHandler := handler.NewCustomerHandler(customerService)
	transactionHandler := handler.NewTransactionHandler(transactionService)
	salesHandler := handler.NewSalesHandler(salesService)
	sparePartHandler := handler.NewSparePartHandler(sparePartService)
	repairHandler := handler.NewRepairHandler(repairService)
	dashboardHandler := handler.NewDashboardHandler(dashboardService)
	supplierHandler := handler.NewSupplierHandler(supplierService)
	userHandler := handler.NewUserHandler(userService)

	// Setup router
	router := setupRouter(cfg, jwtMiddleware, authHandler, vehicleHandler, vehicleTypeHandler, customerHandler, transactionHandler, salesHandler, sparePartHandler, repairHandler, dashboardHandler, supplierHandler, userHandler)

	// Start server
	log.Printf("Starting server on port %s", cfg.Server.Port)
	if err := router.Run(":" + cfg.Server.Port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func setupRouter(cfg *config.Config, jwtMiddleware *middleware.JWTMiddleware, authHandler *handler.AuthHandler, vehicleHandler *handler.VehicleHandler, vehicleTypeHandler *handler.VehicleTypeHandler, customerHandler *handler.CustomerHandler, transactionHandler *handler.TransactionHandler, salesHandler *handler.SalesHandler, sparePartHandler *handler.SparePartHandler, repairHandler *handler.RepairHandler, dashboardHandler *handler.DashboardHandler, supplierHandler *handler.SupplierHandler, userHandler *handler.UserHandler) *gin.Engine {
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
			"status":  "ok",
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
				vehicles.GET("/search", vehicleHandler.SearchVehicles)
				vehicles.GET("/brands", vehicleHandler.GetVehicleBrands)
				vehicles.GET("/available", vehicleHandler.GetAvailableVehicles)
				vehicles.GET("/:id", vehicleHandler.GetVehicle)
				vehicles.POST("", jwtMiddleware.RequireCashierOrAdmin(), vehicleHandler.CreateVehicle)
				vehicles.PUT("/:id", jwtMiddleware.RequireCashierOrAdmin(), vehicleHandler.UpdateVehicle)
				vehicles.DELETE("/:id", jwtMiddleware.RequireAdmin(), vehicleHandler.DeleteVehicle)
				vehicles.PATCH("/:id/selling-price", jwtMiddleware.RequireAdmin(), vehicleHandler.SetSellingPrice)
			}

			// Vehicle Type routes
			vehicleTypes := protected.Group("/vehicle-types")
			{
				vehicleTypes.GET("", vehicleTypeHandler.ListVehicleTypes)
				vehicleTypes.GET("/:id", vehicleTypeHandler.GetVehicleType)
				vehicleTypes.POST("", jwtMiddleware.RequireAdmin(), vehicleTypeHandler.CreateVehicleType)
				vehicleTypes.PUT("/:id", jwtMiddleware.RequireAdmin(), vehicleTypeHandler.UpdateVehicleType)
				vehicleTypes.DELETE("/:id", jwtMiddleware.RequireAdmin(), vehicleTypeHandler.DeleteVehicleType)
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

			// Transaction routes
			transactions := protected.Group("/transactions")
			{
				// Purchase transactions
				purchase := transactions.Group("/purchase")
				{
					purchase.GET("", transactionHandler.ListPurchaseTransactions)
					purchase.GET("/:id", transactionHandler.GetPurchaseTransaction)
					purchase.POST("", jwtMiddleware.RequireCashierOrAdmin(), transactionHandler.CreatePurchaseTransaction)
					purchase.PATCH("/:id/payment", jwtMiddleware.RequireCashierOrAdmin(), transactionHandler.UpdatePurchasePaymentStatus)
				}

				// Sales transactions
				sales := transactions.Group("/sales")
				{
					sales.GET("", transactionHandler.ListSalesTransactions)
					sales.GET("/:id", transactionHandler.GetSalesTransaction)
					sales.POST("", jwtMiddleware.RequireCashierOrAdmin(), transactionHandler.CreateSalesTransaction)
					sales.PATCH("/:id/payment", jwtMiddleware.RequireCashierOrAdmin(), transactionHandler.UpdateSalesPaymentStatus)
				}
			}

			// Sales routes (new dedicated routes)
			sales := protected.Group("/sales")
			{
				sales.POST("/transactions", jwtMiddleware.RequireCashierOrAdmin(), salesHandler.CreateSalesTransaction)
				sales.GET("/transactions", salesHandler.ListSalesTransactions)
				sales.GET("/transactions/:id", salesHandler.GetSalesTransaction)
				sales.PUT("/transactions/:id", jwtMiddleware.RequireCashierOrAdmin(), salesHandler.UpdateSalesTransaction)
				sales.DELETE("/transactions/:id", jwtMiddleware.RequireAdmin(), salesHandler.DeleteSalesTransaction)
				sales.GET("/vehicles/available", salesHandler.GetAvailableVehicles)
			}

			// Spare Parts routes
			spareParts := protected.Group("/spare-parts")
			{
				spareParts.GET("", sparePartHandler.ListSpareParts)
				spareParts.GET("/low-stock", sparePartHandler.GetLowStockItems)
				spareParts.GET("/:id", sparePartHandler.GetSparePart)
				spareParts.GET("/code/:code", sparePartHandler.GetSparePartByCode)
				spareParts.GET("/:id/stock-check", sparePartHandler.CheckStockAvailability)
				spareParts.POST("", jwtMiddleware.RequireCashierOrAdmin(), sparePartHandler.CreateSparePart)
				spareParts.PUT("/:id", jwtMiddleware.RequireCashierOrAdmin(), sparePartHandler.UpdateSparePart)
				spareParts.DELETE("/:id", jwtMiddleware.RequireAdmin(), sparePartHandler.DeleteSparePart)
				spareParts.PATCH("/:id/stock", jwtMiddleware.RequireCashierOrAdmin(), sparePartHandler.UpdateStock)
				spareParts.POST("/bulk-stock-update", jwtMiddleware.RequireCashierOrAdmin(), sparePartHandler.BulkUpdateStock)
			}

			// Repair routes
			repairs := protected.Group("/repairs")
			{
				repairs.GET("", repairHandler.ListRepairOrders)
				repairs.GET("/stats", repairHandler.GetRepairStats)
				repairs.GET("/mechanic-workload", repairHandler.GetMechanicWorkload)
				repairs.GET("/vehicles-needing-orders", repairHandler.GetVehiclesNeedingRepairOrders)
				repairs.GET("/:id", repairHandler.GetRepairOrder)
				repairs.GET("/code/:code", repairHandler.GetRepairOrderByCode)
				repairs.GET("/:id/spare-parts", repairHandler.GetRepairSpareParts)
				repairs.POST("", jwtMiddleware.RequireCashierOrAdmin(), repairHandler.CreateRepairOrder)
				repairs.PUT("/:id", jwtMiddleware.RequireCashierOrAdmin(), repairHandler.UpdateRepairOrder)
				repairs.DELETE("/:id", jwtMiddleware.RequireAdmin(), repairHandler.DeleteRepairOrder)
				repairs.PATCH("/:id/progress", repairHandler.UpdateRepairProgress)   // Mechanics can update their own repairs
				repairs.POST("/:id/spare-parts", repairHandler.AddSparePartToRepair) // Mechanics can add spare parts
				repairs.DELETE("/:id/spare-parts/:spare_part_id", jwtMiddleware.RequireCashierOrAdmin(), repairHandler.RemoveSparePartFromRepair)
			}

			// Dashboard routes
			dashboard := protected.Group("/dashboard")
			{
				dashboard.GET("", dashboardHandler.GetDashboard) // Role-based dashboard
				dashboard.GET("/admin", jwtMiddleware.RequireAdmin(), dashboardHandler.GetAdminDashboard)
				dashboard.GET("/cashier", jwtMiddleware.RequireCashierOrAdmin(), dashboardHandler.GetCashierDashboard)
				dashboard.GET("/mechanic", dashboardHandler.GetMechanicDashboard)                                                     // Current user
				dashboard.GET("/mechanic/:mechanic_id", jwtMiddleware.RequireCashierOrAdmin(), dashboardHandler.GetMechanicDashboard) // Specific mechanic
				dashboard.POST("/daily-closing", jwtMiddleware.RequireCashierOrAdmin(), dashboardHandler.CreateDailyClosing)
				dashboard.POST("/monthly-closing", jwtMiddleware.RequireAdmin(), dashboardHandler.CreateMonthlyClosing)
				dashboard.POST("/update-metrics", jwtMiddleware.RequireAdmin(), dashboardHandler.UpdateMetrics)
			}

			// Supplier routes
			suppliers := protected.Group("/suppliers")
			{
				suppliers.GET("", supplierHandler.ListSuppliers)
				suppliers.GET("/active", supplierHandler.GetActiveSuppliers)
				suppliers.GET("/:id", supplierHandler.GetSupplier)
				suppliers.GET("/phone/:phone", supplierHandler.GetSupplierByPhone)
				suppliers.GET("/email/:email", supplierHandler.GetSupplierByEmail)
				suppliers.POST("", jwtMiddleware.RequireCashierOrAdmin(), supplierHandler.CreateSupplier)
				suppliers.PUT("/:id", jwtMiddleware.RequireCashierOrAdmin(), supplierHandler.UpdateSupplier)
				suppliers.DELETE("/:id", jwtMiddleware.RequireAdmin(), supplierHandler.DeleteSupplier)
			}

			// User management routes
			users := protected.Group("/users")
			{
				users.GET("", jwtMiddleware.RequireAdmin(), userHandler.ListUsers)
				users.GET("/active", jwtMiddleware.RequireCashierOrAdmin(), userHandler.GetActiveUsers)
				users.GET("/role/:role", jwtMiddleware.RequireCashierOrAdmin(), userHandler.GetUsersByRole)
				users.GET("/:id", jwtMiddleware.RequireCashierOrAdmin(), userHandler.GetUser)
				users.GET("/username/:username", jwtMiddleware.RequireCashierOrAdmin(), userHandler.GetUserByUsername)
				users.GET("/email/:email", jwtMiddleware.RequireCashierOrAdmin(), userHandler.GetUserByEmail)
				users.POST("", jwtMiddleware.RequireAdmin(), userHandler.CreateUser)
				users.PUT("/:id", jwtMiddleware.RequireAdmin(), userHandler.UpdateUser)
				users.DELETE("/:id", jwtMiddleware.RequireAdmin(), userHandler.DeleteUser)
				users.POST("/change-password", userHandler.ChangePassword)                                 // Users can change their own password
				users.POST("/:id/reset-password", jwtMiddleware.RequireAdmin(), userHandler.ResetPassword) // Admin can reset any password
				users.PATCH("/:id/toggle-status", jwtMiddleware.RequireAdmin(), userHandler.ToggleUserStatus)
			}
		}
	}

	return router
}
