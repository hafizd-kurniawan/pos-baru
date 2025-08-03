package service

import (
	"fmt"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
)

type VehicleBrandService interface {
	Create(req *models.VehicleBrandCreateRequest) (*models.VehicleBrand, error)
	GetByID(id int) (*models.VehicleBrand, error)
	Update(id int, req *models.VehicleBrandUpdateRequest) (*models.VehicleBrand, error)
	Delete(id int) error
	List(page, limit int) ([]models.VehicleBrand, int64, error)
	GetByTypeID(typeID int) ([]models.VehicleBrand, error)
}

type vehicleBrandService struct {
	brandRepo repository.VehicleBrandRepository
}

func NewVehicleBrandService(brandRepo repository.VehicleBrandRepository) VehicleBrandService {
	return &vehicleBrandService{
		brandRepo: brandRepo,
	}
}

func (s *vehicleBrandService) Create(req *models.VehicleBrandCreateRequest) (*models.VehicleBrand, error) {
	brand, err := s.brandRepo.Create(req)
	if err != nil {
		return nil, fmt.Errorf("failed to create vehicle brand: %w", err)
	}

	return brand, nil
}

func (s *vehicleBrandService) GetByID(id int) (*models.VehicleBrand, error) {
	brand, err := s.brandRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get vehicle brand: %w", err)
	}

	return brand, nil
}

func (s *vehicleBrandService) Update(id int, req *models.VehicleBrandUpdateRequest) (*models.VehicleBrand, error) {
	brand, err := s.brandRepo.Update(id, req)
	if err != nil {
		return nil, fmt.Errorf("failed to update vehicle brand: %w", err)
	}

	return brand, nil
}

func (s *vehicleBrandService) Delete(id int) error {
	err := s.brandRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("failed to delete vehicle brand: %w", err)
	}

	return nil
}

func (s *vehicleBrandService) List(page, limit int) ([]models.VehicleBrand, int64, error) {
	brands, total, err := s.brandRepo.List(page, limit)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list vehicle brands: %w", err)
	}

	return brands, total, nil
}

func (s *vehicleBrandService) GetByTypeID(typeID int) ([]models.VehicleBrand, error) {
	brands, err := s.brandRepo.GetByTypeID(typeID)
	if err != nil {
		return nil, fmt.Errorf("failed to get vehicle brands by type: %w", err)
	}

	return brands, nil
}
