package service

import (
	"fmt"
	"time"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
)

type RepairService interface {
	CreateRepairOrder(request *models.RepairOrderCreateRequest, assignedBy int) (*models.RepairOrder, error)
	GetRepairOrder(id int) (*models.RepairOrder, error)
	GetRepairOrderByCode(code string) (*models.RepairOrder, error)
	ListRepairOrders(filter models.RepairOrderFilter, page, limit int) ([]models.RepairOrder, int, error)
	UpdateRepairOrder(id int, request *models.RepairOrderUpdateRequest) error
	UpdateRepairProgress(id int, request *models.RepairProgressUpdateRequest) error
	DeleteRepairOrder(id int) error

	// Spare parts management
	AddSparePartToRepair(repairID int, request *models.RepairSparePartCreateRequest) error
	RemoveSparePartFromRepair(repairID int, sparePartID int) error
	GetRepairSpareParts(repairID int) ([]models.RepairSparePart, error)

	// Statistics and reporting
	GetRepairStats(mechanicID *int, dateFrom, dateTo *time.Time) (map[string]interface{}, error)
	GetMechanicWorkload() ([]map[string]interface{}, error)

	// Vehicle management
	GetVehiclesNeedingRepairOrders() ([]models.Vehicle, error)
}

type repairService struct {
	repairRepo    repository.RepairRepository
	vehicleRepo   repository.VehicleRepository
	userRepo      repository.UserRepository
	sparePartRepo repository.SparePartRepository
}

func NewRepairService(repairRepo repository.RepairRepository, vehicleRepo repository.VehicleRepository, userRepo repository.UserRepository, sparePartRepo repository.SparePartRepository) RepairService {
	return &repairService{
		repairRepo:    repairRepo,
		vehicleRepo:   vehicleRepo,
		userRepo:      userRepo,
		sparePartRepo: sparePartRepo,
	}
}

func (s *repairService) CreateRepairOrder(request *models.RepairOrderCreateRequest, assignedBy int) (*models.RepairOrder, error) {
	// Validate vehicle exists and status
	vehicle, err := s.vehicleRepo.GetByID(request.VehicleID)
	if err != nil {
		return nil, fmt.Errorf("vehicle not found: %v", err)
	}

	// Check if vehicle can be repaired
	if vehicle.Status == models.VehicleStatusSold {
		return nil, fmt.Errorf("cannot repair sold vehicle")
	}

	// Validate mechanic exists and has correct role
	_, err = s.userRepo.GetByID(request.MechanicID)
	if err != nil {
		return nil, fmt.Errorf("mechanic not found: %v", err)
	}

	// if mechanic.RoleID != 3 { // Assuming role_id 3 is mechanic
	// 	return nil, fmt.Errorf("assigned user is not a mechanic")
	// }

	// Generate repair order code
	code := s.generateRepairCode()

	// Create repair order
	repair := &models.RepairOrder{
		Code:          code,
		VehicleID:     request.VehicleID,
		MechanicID:    request.MechanicID,
		AssignedBy:    assignedBy,
		Description:   request.Description,
		EstimatedCost: request.EstimatedCost,
		Status:        models.RepairStatusPending,
		Notes:         request.Notes,
	}

	err = s.repairRepo.Create(repair)
	if err != nil {
		return nil, fmt.Errorf("failed to create repair order: %v", err)
	}

	// Update vehicle status to in_repair
	err = s.vehicleRepo.UpdateStatus(request.VehicleID, string(models.VehicleStatusInRepair))
	if err != nil {
		return nil, fmt.Errorf("failed to update vehicle status: %v", err)
	}

	// Get complete repair order with relationships
	return s.repairRepo.GetByID(repair.ID)
}

func (s *repairService) GetRepairOrder(id int) (*models.RepairOrder, error) {
	return s.repairRepo.GetByID(id)
}

func (s *repairService) GetRepairOrderByCode(code string) (*models.RepairOrder, error) {
	return s.repairRepo.GetByCode(code)
}

func (s *repairService) ListRepairOrders(filter models.RepairOrderFilter, page, limit int) ([]models.RepairOrder, int, error) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	return s.repairRepo.List(filter, page, limit)
}

func (s *repairService) UpdateRepairOrder(id int, request *models.RepairOrderUpdateRequest) error {
	// Check if repair order exists
	repair, err := s.repairRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("repair order not found: %v", err)
	}

	// Validate status transition if status is being updated
	if request.Status != nil {
		err = s.validateStatusTransition(repair.Status, *request.Status)
		if err != nil {
			return err
		}
	}

	return s.repairRepo.Update(id, request)
}

func (s *repairService) UpdateRepairProgress(id int, request *models.RepairProgressUpdateRequest) error {
	// Check if repair order exists
	repair, err := s.repairRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("repair order not found: %v", err)
	}

	fmt.Printf("UpdateRepairProgress service: repair found ID=%d, current status=%s\n", repair.ID, repair.Status)

	// Validate status transition
	err = s.validateStatusTransition(repair.Status, request.Status)
	if err != nil {
		return err
	}

	fmt.Printf("UpdateRepairProgress service: updating to status=%s\n", request.Status)

	// Update repair progress
	err = s.repairRepo.UpdateProgress(id, request)
	if err != nil {
		return fmt.Errorf("failed to update repair progress: %v", err)
	}

	fmt.Printf("UpdateRepairProgress service: repair progress updated successfully\n")

	// Update vehicle status based on repair status
	var vehicleStatus models.VehicleStatus
	switch request.Status {
	case models.RepairStatusCompleted:
		vehicleStatus = models.VehicleStatusAvailable

		// Always calculate repair cost from spare parts used only
		spareParts, err := s.repairRepo.GetSpareParts(id)
		if err != nil {
			return fmt.Errorf("failed to get spare parts for cost calculation: %v", err)
		}

		totalSparePartsCost := 0.0
		for _, part := range spareParts {
			totalSparePartsCost += part.UnitPrice * float64(part.QuantityUsed)
		}

		// Update vehicle repair cost with spare parts total only
		err = s.vehicleRepo.UpdateRepairCost(repair.VehicleID, totalSparePartsCost)
		if err != nil {
			return fmt.Errorf("failed to update vehicle repair cost: %v", err)
		}

		fmt.Printf("UpdateRepairProgress service: vehicle repair cost updated to %.2f (from spare parts only)\n", totalSparePartsCost)

	case models.RepairStatusCancelled:
		vehicleStatus = models.VehicleStatusAvailable

	case models.RepairStatusInProgress:
		vehicleStatus = models.VehicleStatusInRepair

	default:
		// No vehicle status update needed for pending
		return nil
	}

	err = s.vehicleRepo.UpdateStatus(repair.VehicleID, string(vehicleStatus))
	if err != nil {
		return fmt.Errorf("failed to update vehicle status: %v", err)
	}

	fmt.Printf("UpdateRepairProgress service: vehicle status updated to %s\n", vehicleStatus)

	return nil
}

func (s *repairService) DeleteRepairOrder(id int) error {
	// Check if repair order exists
	repair, err := s.repairRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("repair order not found: %v", err)
	}

	// Only allow deletion if repair is pending or cancelled
	if repair.Status != models.RepairStatusPending && repair.Status != models.RepairStatusCancelled {
		return fmt.Errorf("cannot delete repair order in %s status", repair.Status)
	}

	err = s.repairRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("failed to delete repair order: %v", err)
	}

	// Update vehicle status back to available if it was in repair
	if repair.Status == models.RepairStatusPending {
		err = s.vehicleRepo.UpdateStatus(repair.VehicleID, string(models.VehicleStatusAvailable))
		if err != nil {
			return fmt.Errorf("failed to update vehicle status: %v", err)
		}
	}

	return nil
}

func (s *repairService) AddSparePartToRepair(repairID int, request *models.RepairSparePartCreateRequest) error {
	// Check if repair order exists
	_, err := s.repairRepo.GetByID(repairID)
	if err != nil {
		return fmt.Errorf("repair order not found: %v", err)
	}

	// Check if spare part exists
	_, err = s.sparePartRepo.GetByID(request.SparePartID)
	if err != nil {
		return fmt.Errorf("spare part not found: %v", err)
	}

	return s.repairRepo.AddSparePart(repairID, request)
}

func (s *repairService) RemoveSparePartFromRepair(repairID int, sparePartID int) error {
	// Check if repair order exists
	_, err := s.repairRepo.GetByID(repairID)
	if err != nil {
		return fmt.Errorf("repair order not found: %v", err)
	}

	return s.repairRepo.RemoveSparePart(repairID, sparePartID)
}

func (s *repairService) GetRepairSpareParts(repairID int) ([]models.RepairSparePart, error) {
	// Check if repair order exists
	_, err := s.repairRepo.GetByID(repairID)
	if err != nil {
		return nil, fmt.Errorf("repair order not found: %v", err)
	}

	return s.repairRepo.GetSpareParts(repairID)
}

func (s *repairService) GetRepairStats(mechanicID *int, dateFrom, dateTo *time.Time) (map[string]interface{}, error) {
	return s.repairRepo.GetRepairStats(mechanicID, dateFrom, dateTo)
}

func (s *repairService) GetMechanicWorkload() ([]map[string]interface{}, error) {
	// This would need a separate query to get mechanics and their current workload
	// For now, return empty slice
	return []map[string]interface{}{}, nil
}

func (s *repairService) GetVehiclesNeedingRepairOrders() ([]models.Vehicle, error) {
	// Get all vehicles with in_repair status
	inRepairStatus := models.VehicleStatusInRepair
	vehicles, _, err := s.vehicleRepo.List(1, 100, &inRepairStatus) // Get up to 100 vehicles

	if err != nil {
		return nil, fmt.Errorf("failed to get vehicles: %v", err)
	}

	var vehiclesNeedingOrders []models.Vehicle

	// Check each vehicle to see if it has an active repair order
	for _, vehicle := range vehicles {
		// Check if vehicle has an active repair order (pending or in_progress)
		repairs, _, err := s.repairRepo.List(models.RepairOrderFilter{
			VehicleID: vehicle.ID,
			Status:    "", // Get all statuses
		}, 1, 10)

		if err != nil {
			fmt.Printf("Error checking repairs for vehicle %d: %v\n", vehicle.ID, err)
			continue
		}

		// Check if there's any active repair order (pending or in_progress)
		hasActiveRepair := false
		for _, repair := range repairs {
			if repair.Status == models.RepairStatusPending || repair.Status == models.RepairStatusInProgress {
				hasActiveRepair = true
				break
			}
		}

		// If no active repair order, add to list
		if !hasActiveRepair {
			vehiclesNeedingOrders = append(vehiclesNeedingOrders, vehicle)
		}
	}

	return vehiclesNeedingOrders, nil
}

// Helper methods

func (s *repairService) generateRepairCode() string {
	// Generate repair code in format RPR-YYYYMMDD-XXX
	now := time.Now()
	dateStr := now.Format("20060102")

	// This is a simple implementation. In production, you might want to:
	// 1. Query for the last repair order of the day
	// 2. Increment the sequence number
	// 3. Handle concurrent requests properly

	return fmt.Sprintf("RPR-%s-%03d", dateStr, now.Nanosecond()%1000)
}

func (s *repairService) validateStatusTransition(currentStatus, newStatus models.RepairStatus) error {
	// Define allowed status transitions
	allowedTransitions := map[models.RepairStatus][]models.RepairStatus{
		models.RepairStatusPending: {
			models.RepairStatusInProgress,
			models.RepairStatusCancelled,
		},
		models.RepairStatusInProgress: {
			models.RepairStatusCompleted,
			models.RepairStatusCancelled,
		},
		models.RepairStatusCompleted: {
			// No transitions allowed from completed
		},
		models.RepairStatusCancelled: {
			models.RepairStatusPending, // Allow reactivation
		},
	}

	allowed := allowedTransitions[currentStatus]
	for _, status := range allowed {
		if status == newStatus {
			return nil
		}
	}

	return fmt.Errorf("invalid status transition from %s to %s", currentStatus, newStatus)
}
