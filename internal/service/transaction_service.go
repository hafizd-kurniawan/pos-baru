package service

import (
	"fmt"
	"time"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
)

type TransactionService interface {
	CreatePurchaseTransaction(req *models.PurchaseTransactionCreateRequest, processedBy int) (*models.PurchaseTransaction, error)
	CreateSalesTransaction(req *models.SalesTransactionCreateRequest, processedBy int) (*models.SalesTransaction, error)
	GetPurchaseTransactionByID(id int) (*models.PurchaseTransaction, error)
	GetSalesTransactionByID(id int) (*models.SalesTransaction, error)
	ListPurchaseTransactions(page, limit int, dateFrom, dateTo *time.Time) ([]models.PurchaseTransaction, int64, error)
	ListSalesTransactions(page, limit int, dateFrom, dateTo *time.Time) ([]models.SalesTransaction, int64, error)
	UpdatePurchasePaymentStatus(id int, req *models.PaymentUpdateRequest) error
	UpdateSalesPaymentStatus(id int, req *models.PaymentUpdateRequest) error
}

type transactionService struct {
	transactionRepo repository.TransactionRepository
	vehicleRepo     repository.VehicleRepository
	customerRepo    repository.CustomerRepository
}

func NewTransactionService(
	transactionRepo repository.TransactionRepository,
	vehicleRepo repository.VehicleRepository,
	customerRepo repository.CustomerRepository,
) TransactionService {
	return &transactionService{
		transactionRepo: transactionRepo,
		vehicleRepo:     vehicleRepo,
		customerRepo:    customerRepo,
	}
}

func (s *transactionService) CreatePurchaseTransaction(req *models.PurchaseTransactionCreateRequest, processedBy int) (*models.PurchaseTransaction, error) {
	// Validate vehicle exists and is not sold
	vehicle, err := s.vehicleRepo.GetByID(req.VehicleID)
	if err != nil {
		return nil, fmt.Errorf("vehicle not found")
	}

	if vehicle.Status == models.VehicleStatusSold {
		return nil, fmt.Errorf("vehicle is already sold")
	}

	// Create transaction
	transaction, err := s.transactionRepo.CreatePurchaseTransaction(req, processedBy)
	if err != nil {
		return nil, fmt.Errorf("failed to create purchase transaction: %w", err)
	}

	// Update vehicle information if needed
	updateReq := &models.VehicleUpdateRequest{}
	_, err = s.vehicleRepo.Update(req.VehicleID, updateReq)
	if err != nil {
		return nil, fmt.Errorf("failed to update vehicle information: %w", err)
	}

	return transaction, nil
}

func (s *transactionService) CreateSalesTransaction(req *models.SalesTransactionCreateRequest, processedBy int) (*models.SalesTransaction, error) {
	// Validate vehicle exists and is available
	vehicle, err := s.vehicleRepo.GetByID(req.VehicleID)
	if err != nil {
		return nil, fmt.Errorf("vehicle not found")
	}

	if vehicle.Status != models.VehicleStatusAvailable {
		return nil, fmt.Errorf("vehicle is not available for sale")
	}

	// Validate customer exists
	_, err = s.customerRepo.GetByID(req.CustomerID)
	if err != nil {
		return nil, fmt.Errorf("customer not found")
	}

	// Validate selling price is reasonable (at least HPP)
	if req.SellingPrice < vehicle.HPPPrice {
		return nil, fmt.Errorf("selling price cannot be less than HPP (%.2f)", vehicle.HPPPrice)
	}

	// Create transaction
	transaction, err := s.transactionRepo.CreateSalesTransaction(req, processedBy)
	if err != nil {
		return nil, fmt.Errorf("failed to create sales transaction: %w", err)
	}

	// Mark vehicle as sold
	err = s.vehicleRepo.MarkAsSold(req.VehicleID, req.SellingPrice)
	if err != nil {
		return nil, fmt.Errorf("failed to mark vehicle as sold: %w", err)
	}

	return transaction, nil
}

func (s *transactionService) GetPurchaseTransactionByID(id int) (*models.PurchaseTransaction, error) {
	transaction, err := s.transactionRepo.GetPurchaseTransactionByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get purchase transaction: %w", err)
	}

	return transaction, nil
}

func (s *transactionService) GetSalesTransactionByID(id int) (*models.SalesTransaction, error) {
	transaction, err := s.transactionRepo.GetSalesTransactionByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get sales transaction: %w", err)
	}

	return transaction, nil
}

func (s *transactionService) ListPurchaseTransactions(page, limit int, dateFrom, dateTo *time.Time) ([]models.PurchaseTransaction, int64, error) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	transactions, total, err := s.transactionRepo.ListPurchaseTransactions(page, limit, dateFrom, dateTo)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list purchase transactions: %w", err)
	}

	return transactions, total, nil
}

func (s *transactionService) ListSalesTransactions(page, limit int, dateFrom, dateTo *time.Time) ([]models.SalesTransaction, int64, error) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	transactions, total, err := s.transactionRepo.ListSalesTransactions(page, limit, dateFrom, dateTo)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list sales transactions: %w", err)
	}

	return transactions, total, nil
}

func (s *transactionService) UpdatePurchasePaymentStatus(id int, req *models.PaymentUpdateRequest) error {
	// Check if transaction exists
	_, err := s.transactionRepo.GetPurchaseTransactionByID(id)
	if err != nil {
		return fmt.Errorf("purchase transaction not found")
	}

	// Update payment status
	err = s.transactionRepo.UpdatePurchasePaymentStatus(id, req)
	if err != nil {
		return fmt.Errorf("failed to update purchase payment status: %w", err)
	}

	return nil
}

func (s *transactionService) UpdateSalesPaymentStatus(id int, req *models.PaymentUpdateRequest) error {
	// Check if transaction exists
	transaction, err := s.transactionRepo.GetSalesTransactionByID(id)
	if err != nil {
		return fmt.Errorf("sales transaction not found")
	}

	// Validate payment amounts if provided
	if req.DownPayment != nil && req.RemainingPayment != nil {
		total := *req.DownPayment + *req.RemainingPayment
		if total != transaction.SellingPrice {
			return fmt.Errorf("down payment + remaining payment must equal selling price")
		}
	}

	// Update payment status
	err = s.transactionRepo.UpdateSalesPaymentStatus(id, req)
	if err != nil {
		return fmt.Errorf("failed to update sales payment status: %w", err)
	}

	return nil
}