package service

import (
	"fmt"
	"time"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
)

type SalesService interface {
	CreateTransaction(req *models.SalesTransactionCreateRequest) (*models.SalesTransaction, error)
	GetTransactionByID(id int) (*models.SalesTransaction, error)
	ListTransactions(page, limit int, status, dateFrom, dateTo string, customerID *int) ([]models.SalesTransaction, int64, error)
	UpdateTransaction(id int, req *models.SalesTransactionUpdateRequest) (*models.SalesTransaction, error)
	DeleteTransaction(id int) error
	GetAvailableVehicles(search, brand string, yearFrom, yearTo *int, sortBy, status string) ([]models.Vehicle, error)
}

type salesService struct {
	salesRepo    repository.SalesRepository
	vehicleRepo  repository.VehicleRepository
	customerRepo repository.CustomerRepository
}

func NewSalesService(salesRepo repository.SalesRepository, vehicleRepo repository.VehicleRepository, customerRepo repository.CustomerRepository) SalesService {
	return &salesService{
		salesRepo:    salesRepo,
		vehicleRepo:  vehicleRepo,
		customerRepo: customerRepo,
	}
}

func (s *salesService) CreateTransaction(req *models.SalesTransactionCreateRequest) (*models.SalesTransaction, error) {
	// Validate customer exists
	customer, err := s.customerRepo.GetByID(req.CustomerID)
	if err != nil {
		return nil, fmt.Errorf("customer not found")
	}

	// Validate vehicle exists and available
	vehicle, err := s.vehicleRepo.GetByID(req.VehicleID)
	if err != nil {
		return nil, fmt.Errorf("vehicle not found")
	}

	if vehicle.Status != "available" {
		return nil, fmt.Errorf("vehicle not available for sale")
	}

	// Generate invoice number
	invoiceNumber := s.generateInvoiceNumber()

	// Calculate profit (selling_price - hpp_price)
	profit := req.SellingPrice - vehicle.PurchasePrice

	// Calculate remaining payment
	remainingPayment := req.SellingPrice - req.DownPayment

	// Determine payment status
	paymentStatus := models.PaymentStatusPending
	if req.DownPayment > 0 {
		if remainingPayment > 0 {
			paymentStatus = models.PaymentStatusPartial
		} else {
			paymentStatus = models.PaymentStatusPaid
		}
	}

	if req.PaymentStatus != "" {
		paymentStatus = req.PaymentStatus
	}

	// Create sales transaction
	salesTransaction := &models.SalesTransaction{
		InvoiceNumber:    invoiceNumber,
		TransactionDate:  time.Now(),
		CustomerID:       req.CustomerID,
		VehicleID:        req.VehicleID,
		HPPPrice:         vehicle.PurchasePrice,
		SellingPrice:     req.SellingPrice,
		Profit:           profit,
		PaymentMethod:    req.PaymentMethod,
		PaymentStatus:    paymentStatus,
		DownPayment:      req.DownPayment,
		RemainingPayment: remainingPayment,
		Notes:            req.Notes,
		ProcessedBy:      req.SalespersonID,
	}

	// Save transaction
	savedTransaction, err := s.salesRepo.Create(salesTransaction)
	if err != nil {
		return nil, fmt.Errorf("failed to create sales transaction: %v", err)
	}

	// Update vehicle status to sold
	err = s.vehicleRepo.UpdateStatus(req.VehicleID, "sold")
	if err != nil {
		// Rollback transaction if needed
		return nil, fmt.Errorf("failed to update vehicle status: %v", err)
	}

	// Load relations
	savedTransaction.Customer = customer
	savedTransaction.Vehicle = vehicle

	return savedTransaction, nil
}

func (s *salesService) GetTransactionByID(id int) (*models.SalesTransaction, error) {
	transaction, err := s.salesRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("sales transaction not found")
	}

	return transaction, nil
}

func (s *salesService) ListTransactions(page, limit int, status, dateFrom, dateTo string, customerID *int) ([]models.SalesTransaction, int64, error) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 {
		limit = 10
	}

	offset := (page - 1) * limit

	transactions, total, err := s.salesRepo.List(offset, limit, status, dateFrom, dateTo, customerID)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list sales transactions: %v", err)
	}

	return transactions, total, nil
}

func (s *salesService) UpdateTransaction(id int, req *models.SalesTransactionUpdateRequest) (*models.SalesTransaction, error) {
	// Check if transaction exists
	existingTransaction, err := s.salesRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("sales transaction not found")
	}

	// Update fields if provided
	if req.SellingPrice != nil {
		existingTransaction.SellingPrice = *req.SellingPrice
		// Recalculate profit
		existingTransaction.Profit = existingTransaction.SellingPrice - existingTransaction.HPPPrice
		// Recalculate remaining payment
		existingTransaction.RemainingPayment = existingTransaction.SellingPrice - existingTransaction.DownPayment
	}

	if req.PaymentMethod != nil {
		existingTransaction.PaymentMethod = req.PaymentMethod
	}

	if req.PaymentStatus != nil {
		existingTransaction.PaymentStatus = *req.PaymentStatus
	}

	if req.DownPayment != nil {
		existingTransaction.DownPayment = *req.DownPayment
		// Recalculate remaining payment
		existingTransaction.RemainingPayment = existingTransaction.SellingPrice - existingTransaction.DownPayment
	}

	if req.Notes != nil {
		existingTransaction.Notes = req.Notes
	}

	// Update timestamp
	existingTransaction.UpdatedAt = time.Now()

	// Save updated transaction
	updatedTransaction, err := s.salesRepo.Update(existingTransaction)
	if err != nil {
		return nil, fmt.Errorf("failed to update sales transaction: %v", err)
	}

	return updatedTransaction, nil
}

func (s *salesService) DeleteTransaction(id int) error {
	// Check if transaction exists
	transaction, err := s.salesRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("sales transaction not found")
	}

	// Delete transaction
	err = s.salesRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("failed to delete sales transaction: %v", err)
	}

	// Revert vehicle status back to available
	err = s.vehicleRepo.UpdateStatus(transaction.VehicleID, "available")
	if err != nil {
		// Log error but don't fail the delete operation
		fmt.Printf("Warning: failed to revert vehicle status: %v\n", err)
	}

	return nil
}

func (s *salesService) GetAvailableVehicles(search, brand string, yearFrom, yearTo *int, sortBy, status string) ([]models.Vehicle, error) {
	vehicles, err := s.vehicleRepo.SearchAvailable(search, brand, yearFrom, yearTo, sortBy, status)
	if err != nil {
		return nil, fmt.Errorf("failed to get available vehicles: %v", err)
	}

	return vehicles, nil
}

func (s *salesService) generateInvoiceNumber() string {
	now := time.Now()
	return fmt.Sprintf("INV-SALES-%d%02d%02d-%d",
		now.Year(),
		now.Month(),
		now.Day(),
		now.Unix()%10000,
	)
}
