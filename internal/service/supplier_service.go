package service

import (
	"database/sql"
	"fmt"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
)

type SupplierService interface {
	CreateSupplier(req *models.SupplierCreateRequest) (*models.Supplier, error)
	GetSupplier(id int) (*models.Supplier, error)
	GetSupplierByPhone(phone string) (*models.Supplier, error)
	GetSupplierByEmail(email string) (*models.Supplier, error)
	UpdateSupplier(id int, req *models.SupplierUpdateRequest) (*models.Supplier, error)
	DeleteSupplier(id int) error
	ListSuppliers(page, limit int, search string, isActive *bool) ([]models.Supplier, int, error)
}

type supplierService struct {
	supplierRepo repository.SupplierRepository
}

func NewSupplierService(supplierRepo repository.SupplierRepository) SupplierService {
	return &supplierService{
		supplierRepo: supplierRepo,
	}
}

func (s *supplierService) CreateSupplier(req *models.SupplierCreateRequest) (*models.Supplier, error) {
	// Check for duplicate phone or email if provided
	if req.Phone != nil && *req.Phone != "" {
		exists, err := s.supplierRepo.CheckSupplierExists(*req.Phone, "", nil)
		if err != nil {
			return nil, fmt.Errorf("failed to check phone existence: %w", err)
		}
		if exists {
			return nil, fmt.Errorf("supplier with this phone number already exists")
		}
	}
	
	if req.Email != nil && *req.Email != "" {
		exists, err := s.supplierRepo.CheckSupplierExists("", *req.Email, nil)
		if err != nil {
			return nil, fmt.Errorf("failed to check email existence: %w", err)
		}
		if exists {
			return nil, fmt.Errorf("supplier with this email already exists")
		}
	}
	
	supplier, err := s.supplierRepo.CreateSupplier(req)
	if err != nil {
		return nil, fmt.Errorf("failed to create supplier: %w", err)
	}
	
	return supplier, nil
}

func (s *supplierService) GetSupplier(id int) (*models.Supplier, error) {
	supplier, err := s.supplierRepo.GetSupplierByID(id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("supplier not found")
		}
		return nil, fmt.Errorf("failed to get supplier: %w", err)
	}
	
	return supplier, nil
}

func (s *supplierService) GetSupplierByPhone(phone string) (*models.Supplier, error) {
	if phone == "" {
		return nil, fmt.Errorf("phone number is required")
	}
	
	supplier, err := s.supplierRepo.GetSupplierByPhone(phone)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("supplier not found")
		}
		return nil, fmt.Errorf("failed to get supplier by phone: %w", err)
	}
	
	return supplier, nil
}

func (s *supplierService) GetSupplierByEmail(email string) (*models.Supplier, error) {
	if email == "" {
		return nil, fmt.Errorf("email is required")
	}
	
	supplier, err := s.supplierRepo.GetSupplierByEmail(email)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("supplier not found")
		}
		return nil, fmt.Errorf("failed to get supplier by email: %w", err)
	}
	
	return supplier, nil
}

func (s *supplierService) UpdateSupplier(id int, req *models.SupplierUpdateRequest) (*models.Supplier, error) {
	// Check if supplier exists
	_, err := s.GetSupplier(id)
	if err != nil {
		return nil, err
	}
	
	// Check for duplicate phone or email if being updated
	if req.Phone != nil && *req.Phone != "" {
		exists, err := s.supplierRepo.CheckSupplierExists(*req.Phone, "", &id)
		if err != nil {
			return nil, fmt.Errorf("failed to check phone existence: %w", err)
		}
		if exists {
			return nil, fmt.Errorf("another supplier with this phone number already exists")
		}
	}
	
	if req.Email != nil && *req.Email != "" {
		exists, err := s.supplierRepo.CheckSupplierExists("", *req.Email, &id)
		if err != nil {
			return nil, fmt.Errorf("failed to check email existence: %w", err)
		}
		if exists {
			return nil, fmt.Errorf("another supplier with this email already exists")
		}
	}
	
	supplier, err := s.supplierRepo.UpdateSupplier(id, req)
	if err != nil {
		return nil, fmt.Errorf("failed to update supplier: %w", err)
	}
	
	return supplier, nil
}

func (s *supplierService) DeleteSupplier(id int) error {
	// Check if supplier exists
	_, err := s.GetSupplier(id)
	if err != nil {
		return err
	}
	
	// TODO: Check if supplier has any related purchase transactions
	// For now, we'll allow deletion (soft delete anyway)
	
	err = s.supplierRepo.DeleteSupplier(id)
	if err != nil {
		return fmt.Errorf("failed to delete supplier: %w", err)
	}
	
	return nil
}

func (s *supplierService) ListSuppliers(page, limit int, search string, isActive *bool) ([]models.Supplier, int, error) {
	// Validate pagination
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	if limit > 100 {
		limit = 100
	}
	
	suppliers, total, err := s.supplierRepo.ListSuppliers(page, limit, search, isActive)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list suppliers: %w", err)
	}
	
	return suppliers, total, nil
}