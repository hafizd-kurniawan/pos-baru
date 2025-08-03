package service

import (
	"fmt"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
)

type CustomerService interface {
	Create(req *models.CustomerCreateRequest) (*models.Customer, error)
	GetByID(id int) (*models.Customer, error)
	Update(id int, req *models.CustomerUpdateRequest) (*models.Customer, error)
	Delete(id int) error
	List(page, limit int) ([]models.Customer, int64, error)
	GetByPhone(phone string) (*models.Customer, error)
	GetByEmail(email string) (*models.Customer, error)
}

type customerService struct {
	customerRepo repository.CustomerRepository
}

func NewCustomerService(customerRepo repository.CustomerRepository) CustomerService {
	return &customerService{
		customerRepo: customerRepo,
	}
}

func (s *customerService) Create(req *models.CustomerCreateRequest) (*models.Customer, error) {
	// Check if phone already exists (if provided)
	if req.Phone != nil && *req.Phone != "" {
		existingCustomer, _ := s.customerRepo.GetByPhone(*req.Phone)
		if existingCustomer != nil {
			return nil, fmt.Errorf("customer with this phone number already exists")
		}
	}

	// Check if email already exists (if provided)
	if req.Email != nil && *req.Email != "" {
		existingCustomer, _ := s.customerRepo.GetByEmail(*req.Email)
		if existingCustomer != nil {
			return nil, fmt.Errorf("customer with this email already exists")
		}
	}

	// Create customer
	customer, err := s.customerRepo.Create(req)
	if err != nil {
		return nil, fmt.Errorf("failed to create customer: %w", err)
	}

	return customer, nil
}

func (s *customerService) GetByID(id int) (*models.Customer, error) {
	customer, err := s.customerRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get customer: %w", err)
	}

	return customer, nil
}

func (s *customerService) Update(id int, req *models.CustomerUpdateRequest) (*models.Customer, error) {
	// Check if customer exists
	_, err := s.customerRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("customer not found")
	}

	// Check if phone already exists (if being updated)
	if req.Phone != nil && *req.Phone != "" {
		existingCustomer, _ := s.customerRepo.GetByPhone(*req.Phone)
		if existingCustomer != nil && existingCustomer.ID != id {
			return nil, fmt.Errorf("another customer with this phone number already exists")
		}
	}

	// Check if email already exists (if being updated)
	if req.Email != nil && *req.Email != "" {
		existingCustomer, _ := s.customerRepo.GetByEmail(*req.Email)
		if existingCustomer != nil && existingCustomer.ID != id {
			return nil, fmt.Errorf("another customer with this email already exists")
		}
	}

	// Update customer
	customer, err := s.customerRepo.Update(id, req)
	if err != nil {
		return nil, fmt.Errorf("failed to update customer: %w", err)
	}

	return customer, nil
}

func (s *customerService) Delete(id int) error {
	// Check if customer exists
	_, err := s.customerRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("customer not found")
	}

	// Delete customer
	err = s.customerRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("failed to delete customer: %w", err)
	}

	return nil
}

func (s *customerService) List(page, limit int) ([]models.Customer, int64, error) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	customers, total, err := s.customerRepo.List(page, limit)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list customers: %w", err)
	}

	return customers, total, nil
}

func (s *customerService) GetByPhone(phone string) (*models.Customer, error) {
	customer, err := s.customerRepo.GetByPhone(phone)
	if err != nil {
		return nil, fmt.Errorf("failed to get customer by phone: %w", err)
	}

	return customer, nil
}

func (s *customerService) GetByEmail(email string) (*models.Customer, error) {
	customer, err := s.customerRepo.GetByEmail(email)
	if err != nil {
		return nil, fmt.Errorf("failed to get customer by email: %w", err)
	}

	return customer, nil
}