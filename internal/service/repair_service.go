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
}

type repairService struct {
	repairRepo   repository.RepairRepository
	vehicleRepo  repository.VehicleRepository
	userRepo     repository.UserRepository
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
	mechanic, err := s.userRepo.GetByID(request.MechanicID)
	if err != nil {
		return nil, fmt.Errorf("mechanic not found: %v", err)
	}
	
	if mechanic.RoleID != 3 { // Assuming role_id 3 is mechanic
		return nil, fmt.Errorf("assigned user is not a mechanic")
	}
	
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
	err = s.vehicleRepo.UpdateStatus(request.VehicleID, models.VehicleStatusInRepair)
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
	
	// Validate status transition
	err = s.validateStatusTransition(repair.Status, request.Status)
	if err != nil {
		return err
	}
	
	// Update repair progress
	err = s.repairRepo.UpdateProgress(id, request)
	if err != nil {
		return fmt.Errorf("failed to update repair progress: %v", err)
	}
	
	// Update vehicle status based on repair status
	var vehicleStatus models.VehicleStatus
	switch request.Status {
	case models.RepairStatusCompleted:
		vehicleStatus = models.VehicleStatusAvailable
		
		// Update vehicle repair cost
		if request.ActualCost != nil {
			err = s.vehicleRepo.UpdateRepairCost(repair.VehicleID, *request.ActualCost)
			if err != nil {
				return fmt.Errorf("failed to update vehicle repair cost: %v", err)
			}
		}
		
	case models.RepairStatusCancelled:
		vehicleStatus = models.VehicleStatusAvailable
		
	case models.RepairStatusInProgress:
		vehicleStatus = models.VehicleStatusInRepair
		
	default:
		// No vehicle status update needed for pending
		return nil
	}
	
	err = s.vehicleRepo.UpdateStatus(repair.VehicleID, vehicleStatus)
	if err != nil {
		return fmt.Errorf("failed to update vehicle status: %v", err)
	}
	
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
		err = s.vehicleRepo.UpdateStatus(repair.VehicleID, models.VehicleStatusAvailable)
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