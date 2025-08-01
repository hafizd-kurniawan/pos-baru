package service

import (
	"fmt"
	"time"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
)

type DashboardService interface {
	GetAdminDashboard() (*models.AdminDashboardResponse, error)
	GetCashierDashboard() (*models.CashierDashboardResponse, error)
	GetMechanicDashboard(mechanicID int) (*models.MechanicDashboardResponse, error)
	CreateDailyClosing(userID int, req *models.DailyClosingCreateRequest) (*models.DailyClosing, error)
	CreateMonthlyClosing(userID int, req *models.MonthlyClosingCreateRequest) (*models.MonthlyClosing, error)
	UpdateMetrics() error
}

type dashboardService struct {
	dashboardRepo repository.DashboardRepository
}

func NewDashboardService(dashboardRepo repository.DashboardRepository) DashboardService {
	return &dashboardService{
		dashboardRepo: dashboardRepo,
	}
}

func (s *dashboardService) GetAdminDashboard() (*models.AdminDashboardResponse, error) {
	today := time.Now()
	
	// Get base dashboard data
	baseDashboard, err := s.getBaseDashboard(today)
	if err != nil {
		return nil, fmt.Errorf("failed to get base dashboard: %w", err)
	}
	
	// Get monthly stats
	monthlyStats, err := s.dashboardRepo.GetMonthlyStats(int(today.Month()), today.Year())
	if err != nil {
		return nil, fmt.Errorf("failed to get monthly stats: %w", err)
	}
	
	// Get top performance data
	topPerformance, err := s.dashboardRepo.GetTopPerformance()
	if err != nil {
		return nil, fmt.Errorf("failed to get top performance: %w", err)
	}
	
	return &models.AdminDashboardResponse{
		DashboardResponse: *baseDashboard,
		MonthlyStats:      *monthlyStats,
		TopPerformance:    topPerformance,
	}, nil
}

func (s *dashboardService) GetCashierDashboard() (*models.CashierDashboardResponse, error) {
	today := time.Now()
	
	// Get base dashboard data
	baseDashboard, err := s.getBaseDashboard(today)
	if err != nil {
		return nil, fmt.Errorf("failed to get base dashboard: %w", err)
	}
	
	// Get today's transactions
	todayTransactions, err := s.dashboardRepo.GetTodayTransactions(today)
	if err != nil {
		return nil, fmt.Errorf("failed to get today transactions: %w", err)
	}
	
	// Get pending payments
	pendingPayments, err := s.dashboardRepo.GetPendingPayments(10)
	if err != nil {
		return nil, fmt.Errorf("failed to get pending payments: %w", err)
	}
	
	return &models.CashierDashboardResponse{
		DashboardResponse: *baseDashboard,
		TodayTransactions: todayTransactions,
		PendingPayments:   pendingPayments,
	}, nil
}

func (s *dashboardService) GetMechanicDashboard(mechanicID int) (*models.MechanicDashboardResponse, error) {
	today := time.Now()
	
	// Get assigned repairs
	assignedRepairs, err := s.dashboardRepo.GetAssignedRepairs(mechanicID)
	if err != nil {
		return nil, fmt.Errorf("failed to get assigned repairs: %w", err)
	}
	
	// Get completed repairs today
	completedToday, err := s.dashboardRepo.GetCompletedRepairsToday(mechanicID, today)
	if err != nil {
		return nil, fmt.Errorf("failed to get completed repairs today: %w", err)
	}
	
	// Get required parts
	requiredParts, err := s.dashboardRepo.GetRequiredPartsForRepairs(mechanicID)
	if err != nil {
		return nil, fmt.Errorf("failed to get required parts: %w", err)
	}
	
	return &models.MechanicDashboardResponse{
		AssignedRepairs: assignedRepairs,
		CompletedToday:  completedToday,
		RequiredParts:   requiredParts,
	}, nil
}

func (s *dashboardService) getBaseDashboard(today time.Time) (*models.DashboardResponse, error) {
	// Get dashboard metrics
	overview, err := s.dashboardRepo.GetDashboardMetrics(today)
	if err != nil {
		return nil, fmt.Errorf("failed to get dashboard metrics: %w", err)
	}
	
	// Get recent transactions
	recentTransactions, err := s.dashboardRepo.GetRecentTransactions(10)
	if err != nil {
		return nil, fmt.Errorf("failed to get recent transactions: %w", err)
	}
	
	// Get pending repairs
	pendingRepairs, err := s.dashboardRepo.GetPendingRepairs(5)
	if err != nil {
		return nil, fmt.Errorf("failed to get pending repairs: %w", err)
	}
	
	// Get low stock items
	lowStockItems, err := s.dashboardRepo.GetLowStockItems(5)
	if err != nil {
		return nil, fmt.Errorf("failed to get low stock items: %w", err)
	}
	
	// Get available vehicles
	availableVehicles, err := s.dashboardRepo.GetAvailableVehicles(5)
	if err != nil {
		return nil, fmt.Errorf("failed to get available vehicles: %w", err)
	}
	
	return &models.DashboardResponse{
		Overview:          *overview,
		RecentTransactions: recentTransactions,
		PendingRepairs:    pendingRepairs,
		LowStockItems:     lowStockItems,
		AvailableVehicles: availableVehicles,
	}, nil
}

func (s *dashboardService) CreateDailyClosing(userID int, req *models.DailyClosingCreateRequest) (*models.DailyClosing, error) {
	// Validate request
	if req.ClosingDate.After(time.Now()) {
		return nil, fmt.Errorf("closing date cannot be in the future")
	}
	
	if req.CashInHand < 0 {
		return nil, fmt.Errorf("cash in hand cannot be negative")
	}
	
	// Create daily closing
	closing, err := s.dashboardRepo.CreateDailyClosing(userID, req)
	if err != nil {
		return nil, fmt.Errorf("failed to create daily closing: %w", err)
	}
	
	return closing, nil
}

func (s *dashboardService) CreateMonthlyClosing(userID int, req *models.MonthlyClosingCreateRequest) (*models.MonthlyClosing, error) {
	// Validate request
	currentTime := time.Now()
	if req.Year > currentTime.Year() || (req.Year == currentTime.Year() && req.Month > int(currentTime.Month())) {
		return nil, fmt.Errorf("cannot close future months")
	}
	
	// Create monthly closing
	closing, err := s.dashboardRepo.CreateMonthlyClosing(userID, req)
	if err != nil {
		return nil, fmt.Errorf("failed to create monthly closing: %w", err)
	}
	
	return closing, nil
}

func (s *dashboardService) UpdateMetrics() error {
	today := time.Now()
	
	err := s.dashboardRepo.UpdateDashboardMetrics(today)
	if err != nil {
		return fmt.Errorf("failed to update dashboard metrics: %w", err)
	}
	
	return nil
}