package service

import (
	"fmt"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
)

type VehicleTypeService interface {
	Create(req *models.VehicleTypeCreateRequest) (*models.VehicleType, error)
	GetByID(id int) (*models.VehicleType, error)
	Update(id int, req *models.VehicleTypeUpdateRequest) (*models.VehicleType, error)
	Delete(id int) error
	List() ([]models.VehicleType, error)
}

type vehicleTypeService struct {
	vehicleTypeRepo repository.VehicleTypeRepository
}

func NewVehicleTypeService(vehicleTypeRepo repository.VehicleTypeRepository) VehicleTypeService {
	return &vehicleTypeService{
		vehicleTypeRepo: vehicleTypeRepo,
	}
}

func (s *vehicleTypeService) Create(req *models.VehicleTypeCreateRequest) (*models.VehicleType, error) {
	// Check if name already exists
	existingType, _ := s.vehicleTypeRepo.GetByName(req.Name)
	if existingType != nil {
		return nil, fmt.Errorf("vehicle type name already exists")
	}

	// Create vehicle type
	vehicleType, err := s.vehicleTypeRepo.Create(req)
	if err != nil {
		return nil, fmt.Errorf("failed to create vehicle type: %w", err)
	}

	return vehicleType, nil
}

func (s *vehicleTypeService) GetByID(id int) (*models.VehicleType, error) {
	vehicleType, err := s.vehicleTypeRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get vehicle type: %w", err)
	}

	return vehicleType, nil
}

func (s *vehicleTypeService) Update(id int, req *models.VehicleTypeUpdateRequest) (*models.VehicleType, error) {
	// Check if vehicle type exists
	_, err := s.vehicleTypeRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("vehicle type not found")
	}

	// If updating name, check if new name already exists
	if req.Name != nil {
		existingType, _ := s.vehicleTypeRepo.GetByName(*req.Name)
		if existingType != nil && existingType.ID != id {
			return nil, fmt.Errorf("vehicle type name already exists")
		}
	}

	// Update vehicle type
	vehicleType, err := s.vehicleTypeRepo.Update(id, req)
	if err != nil {
		return nil, fmt.Errorf("failed to update vehicle type: %w", err)
	}

	return vehicleType, nil
}

func (s *vehicleTypeService) Delete(id int) error {
	// Check if vehicle type exists
	_, err := s.vehicleTypeRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("vehicle type not found")
	}

	// TODO: Check if there are any vehicles using this type
	// For now, we'll allow deletion

	// Delete vehicle type
	err = s.vehicleTypeRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("failed to delete vehicle type: %w", err)
	}

	return nil
}

func (s *vehicleTypeService) List() ([]models.VehicleType, error) {
	vehicleTypes, err := s.vehicleTypeRepo.List()
	if err != nil {
		return nil, fmt.Errorf("failed to list vehicle types: %w", err)
	}

	return vehicleTypes, nil
}
