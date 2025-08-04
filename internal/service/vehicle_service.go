package service

import (
	"fmt"
	"log"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
	"github.com/hafizd-kurniawan/pos-baru/pkg/utils"
)

type VehicleService interface {
	Create(req *models.VehicleCreateRequest, createdBy int) (*models.Vehicle, error)
	GetByID(id int) (*models.Vehicle, error)
	Update(id int, req *models.VehicleUpdateRequest) (*models.Vehicle, error)
	Delete(id int) error
	List(page, limit int, status *models.VehicleStatus) ([]models.Vehicle, int64, error)
	GetAvailableVehicles(page, limit int) ([]models.Vehicle, int64, error)
	GetVehiclesInRepair(page, limit int) ([]models.Vehicle, int64, error)
	SetSellingPrice(id int, sellingPrice float64) error
	MarkForRepair(id int) error
	CompleteRepair(id int, repairCost float64) error
	CalculateHPP(id int) error
	SearchVehicles(page, limit int, filters models.VehicleSearchFilters) ([]models.Vehicle, int64, error)
	GetAllBrands() ([]models.VehicleBrand, error)
}

type vehicleService struct {
	vehicleRepo repository.VehicleRepository
}

func NewVehicleService(vehicleRepo repository.VehicleRepository) VehicleService {
	return &vehicleService{
		vehicleRepo: vehicleRepo,
	}
}

func (s *vehicleService) Create(req *models.VehicleCreateRequest, createdBy int) (*models.Vehicle, error) {
	// Generate unique vehicle code if not provided
	if req.Code == "" {
		code, err := s.generateUniqueVehicleCode()
		if err != nil {
			return nil, fmt.Errorf("failed to generate vehicle code: %w", err)
		}
		req.Code = code
	}

	// Double check if code already exists
	existingVehicle, _ := s.vehicleRepo.GetByCode(req.Code)
	if existingVehicle != nil {
		return nil, fmt.Errorf("vehicle code already exists: %s", req.Code)
	}

	// Create vehicle
	vehicle, err := s.vehicleRepo.Create(req, createdBy)
	if err != nil {
		return nil, fmt.Errorf("failed to create vehicle: %w", err)
	}

	// Calculate initial HPP (purchase price only, no repair cost yet)
	hpp := utils.CalculateHPP(vehicle.PurchasePrice, 0)
	err = s.vehicleRepo.UpdateHPPPrice(vehicle.ID, hpp)
	if err != nil {
		return nil, fmt.Errorf("failed to update HPP price: %w", err)
	}

	vehicle.HPPPrice = &hpp

	return vehicle, nil
}

func (s *vehicleService) GetByID(id int) (*models.Vehicle, error) {
	vehicle, err := s.vehicleRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get vehicle: %w", err)
	}

	return vehicle, nil
}

func (s *vehicleService) Update(id int, req *models.VehicleUpdateRequest) (*models.Vehicle, error) {
	// Check if vehicle exists
	_, err := s.vehicleRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("vehicle not found")
	}

	// Update vehicle
	vehicle, err := s.vehicleRepo.Update(id, req)
	if err != nil {
		return nil, fmt.Errorf("failed to update vehicle: %w", err)
	}

	return vehicle, nil
}

func (s *vehicleService) Delete(id int) error {
	// Check if vehicle exists
	vehicle, err := s.vehicleRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("vehicle not found")
	}

	// Don't allow deletion of sold vehicles
	if vehicle.Status == models.VehicleStatusSold {
		return fmt.Errorf("cannot delete sold vehicle")
	}

	// Delete vehicle
	err = s.vehicleRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("failed to delete vehicle: %w", err)
	}

	return nil
}

func (s *vehicleService) List(page, limit int, status *models.VehicleStatus) ([]models.Vehicle, int64, error) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	vehicles, total, err := s.vehicleRepo.List(page, limit, status)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list vehicles: %w", err)
	}

	return vehicles, total, nil
}

func (s *vehicleService) GetAvailableVehicles(page, limit int) ([]models.Vehicle, int64, error) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	vehicles, total, err := s.vehicleRepo.GetAvailableVehicles(page, limit)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get available vehicles: %w", err)
	}

	return vehicles, total, nil
}

func (s *vehicleService) GetVehiclesInRepair(page, limit int) ([]models.Vehicle, int64, error) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	vehicles, total, err := s.vehicleRepo.GetVehiclesInRepair(page, limit)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get vehicles in repair: %w", err)
	}

	return vehicles, total, nil
}

func (s *vehicleService) SetSellingPrice(id int, sellingPrice float64) error {
	// Check if vehicle exists and is available
	vehicle, err := s.vehicleRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("vehicle not found")
	}

	if vehicle.Status != models.VehicleStatusAvailable {
		return fmt.Errorf("can only set selling price for available vehicles")
	}

	// Update selling price
	err = s.vehicleRepo.UpdateSellingPrice(id, sellingPrice)
	if err != nil {
		return fmt.Errorf("failed to update selling price: %w", err)
	}

	return nil
}

func (s *vehicleService) MarkForRepair(id int) error {
	// Check if vehicle exists
	vehicle, err := s.vehicleRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("vehicle not found")
	}

	// Can only mark available vehicles for repair
	if vehicle.Status != models.VehicleStatusAvailable {
		return fmt.Errorf("can only mark available vehicles for repair")
	}

	// Update status to in_repair
	err = s.vehicleRepo.UpdateStatus(id, string(models.VehicleStatusInRepair))
	if err != nil {
		return fmt.Errorf("failed to mark vehicle for repair: %w", err)
	}

	return nil
}

func (s *vehicleService) CompleteRepair(id int, repairCost float64) error {
	// Check if vehicle exists and is in repair
	vehicle, err := s.vehicleRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("vehicle not found")
	}

	if vehicle.Status != models.VehicleStatusInRepair {
		return fmt.Errorf("vehicle is not in repair")
	}

	// Update repair cost and status
	updateReq := &models.VehicleUpdateRequest{
		Status: &[]models.VehicleStatus{models.VehicleStatusAvailable}[0],
	}

	_, err = s.vehicleRepo.Update(id, updateReq)
	if err != nil {
		return fmt.Errorf("failed to complete repair: %w", err)
	}

	// Recalculate HPP with repair cost
	err = s.CalculateHPP(id)
	if err != nil {
		return fmt.Errorf("failed to recalculate HPP: %w", err)
	}

	return nil
}

func (s *vehicleService) CalculateHPP(id int) error {
	// Get vehicle to calculate HPP
	vehicle, err := s.vehicleRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("vehicle not found")
	}

	// Calculate HPP = Purchase Price + Repair Cost
	repairCost := float64(0)
	if vehicle.RepairCost != nil {
		repairCost = *vehicle.RepairCost
	}
	hpp := utils.CalculateHPP(vehicle.PurchasePrice, repairCost)

	// Update HPP price
	err = s.vehicleRepo.UpdateHPPPrice(id, hpp)
	if err != nil {
		return fmt.Errorf("failed to update HPP price: %w", err)
	}

	return nil
}

// generateUniqueVehicleCode generates a unique vehicle code in VEH001, VEH002, etc. format
func (s *vehicleService) generateUniqueVehicleCode() (string, error) {
	// Start with a simple sequential approach
	for i := 1; i <= 9999; i++ {
		code := fmt.Sprintf("VEH%03d", i)

		// Check if code exists
		existing, _ := s.vehicleRepo.GetByCode(code)
		if existing == nil {
			log.Printf("VehicleService.generateUniqueVehicleCode - Generated code: %s", code)
			return code, nil
		}
	}

	// If we somehow reach here, return error
	return "", fmt.Errorf("unable to generate unique vehicle code: all codes 1-9999 are used")
}

func (s *vehicleService) SearchVehicles(page, limit int, filters models.VehicleSearchFilters) ([]models.Vehicle, int64, error) {
	offset := (page - 1) * limit
	vehicles, totalCount, err := s.vehicleRepo.SearchVehicles(offset, limit, filters)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to search vehicles: %w", err)
	}

	return vehicles, totalCount, nil
}

func (s *vehicleService) GetAllBrands() ([]models.VehicleBrand, error) {
	return s.vehicleRepo.GetAllBrands()
}
