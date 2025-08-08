package service

import (
	"fmt"
	"strings"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
)

type SparePartService interface {
	Create(req *models.SparePartCreateRequest) (*models.SparePart, error)
	GetByID(id int) (*models.SparePart, error)
	GetByCode(code string) (*models.SparePart, error)
	Update(id int, req *models.SparePartUpdateRequest) (*models.SparePart, error)
	Delete(id int) error
	List(page, limit int, isActive *bool) ([]models.SparePart, int64, error)
	ListWithFilters(page, limit int, search, category string, isActive *bool, statusFilter string) ([]models.SparePart, int64, error)
	UpdateStock(id int, quantity int, operation string) error
	GetLowStockItems(page, limit int) ([]models.SparePart, int64, error)
	CheckStockAvailability(id int, requestedQuantity int) (bool, error)
	BulkUpdateStock(updates []models.SparePartStockUpdate) error
	GetCategories() ([]string, error)
	// Category management methods
	GetCategoriesWithPagination(page, limit int, search string) ([]models.CategoryInfo, int64, error)
	CreateCategory(name, description string) error
	UpdateCategory(id int, name, description string) error
	DeleteCategory(id int) error
	GetCategoryStats() ([]models.CategoryStats, error)
}

type sparePartService struct {
	sparePartRepo repository.SparePartRepository
}

func NewSparePartService(sparePartRepo repository.SparePartRepository) SparePartService {
	return &sparePartService{
		sparePartRepo: sparePartRepo,
	}
}

func (s *sparePartService) Create(req *models.SparePartCreateRequest) (*models.SparePart, error) {
	// Check if code already exists
	existingSparePart, _ := s.sparePartRepo.GetByCode(req.Code)
	if existingSparePart != nil {
		return nil, fmt.Errorf("spare part with this code already exists")
	}

	// Validate selling price is greater than or equal to purchase price
	if req.SellingPrice < req.PurchasePrice {
		return nil, fmt.Errorf("selling price cannot be less than purchase price")
	}

	// Create spare part
	sparePart, err := s.sparePartRepo.Create(req)
	if err != nil {
		return nil, fmt.Errorf("failed to create spare part: %w", err)
	}

	return sparePart, nil
}

func (s *sparePartService) GetByID(id int) (*models.SparePart, error) {
	sparePart, err := s.sparePartRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get spare part: %w", err)
	}

	return sparePart, nil
}

func (s *sparePartService) GetByCode(code string) (*models.SparePart, error) {
	sparePart, err := s.sparePartRepo.GetByCode(code)
	if err != nil {
		return nil, fmt.Errorf("failed to get spare part: %w", err)
	}

	return sparePart, nil
}

func (s *sparePartService) Update(id int, req *models.SparePartUpdateRequest) (*models.SparePart, error) {
	// Check if spare part exists
	_, err := s.sparePartRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("spare part not found")
	}

	// Validate selling price is greater than or equal to purchase price (if both are provided)
	if req.SellingPrice != nil && req.PurchasePrice != nil {
		if *req.SellingPrice < *req.PurchasePrice {
			return nil, fmt.Errorf("selling price cannot be less than purchase price")
		}
	}

	// Update spare part
	sparePart, err := s.sparePartRepo.Update(id, req)
	if err != nil {
		return nil, fmt.Errorf("failed to update spare part: %w", err)
	}

	return sparePart, nil
}

func (s *sparePartService) Delete(id int) error {
	// Check if spare part exists
	_, err := s.sparePartRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("spare part not found")
	}

	// Delete spare part
	err = s.sparePartRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("failed to delete spare part: %w", err)
	}

	return nil
}

func (s *sparePartService) List(page, limit int, isActive *bool) ([]models.SparePart, int64, error) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	spareParts, total, err := s.sparePartRepo.List(page, limit, isActive)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list spare parts: %w", err)
	}

	return spareParts, total, nil
}

func (s *sparePartService) ListWithFilters(page, limit int, search, category string, isActive *bool, statusFilter string) ([]models.SparePart, int64, error) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	// Use repository's ListWithFilters method for better performance
	spareParts, total, err := s.sparePartRepo.ListWithFilters(page, limit, search, category, isActive)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list spare parts with filters: %w", err)
	}

	// Apply additional status filter if needed
	if statusFilter != "" {
		filteredSpareParts := make([]models.SparePart, 0)
		for _, sp := range spareParts {
			switch statusFilter {
			case "low_stock":
				// Low stock: stock is greater than 0 but less than or equal to minimum stock
				if sp.IsActive && sp.StockQuantity > 0 && sp.StockQuantity <= sp.MinimumStock {
					filteredSpareParts = append(filteredSpareParts, sp)
				}
			case "out_of_stock":
				// Out of stock: stock quantity is 0
				if sp.StockQuantity == 0 {
					filteredSpareParts = append(filteredSpareParts, sp)
				}
			case "in_stock":
				// In stock: stock is above minimum stock level
				if sp.IsActive && sp.StockQuantity > sp.MinimumStock {
					filteredSpareParts = append(filteredSpareParts, sp)
				}
			case "available":
				// Available: active items with stock > 0
				if sp.IsActive && sp.StockQuantity > 0 {
					filteredSpareParts = append(filteredSpareParts, sp)
				}
			case "inactive":
				// Inactive items
				if !sp.IsActive {
					filteredSpareParts = append(filteredSpareParts, sp)
				}
			}
		}
		spareParts = filteredSpareParts
		total = int64(len(filteredSpareParts))
	}

	return spareParts, total, nil
}

// Helper function for case-insensitive search
func containsIgnoreCase(s, substr string) bool {
	s = strings.ToLower(s)
	substr = strings.ToLower(substr)
	return strings.Contains(s, substr)
}

func (s *sparePartService) UpdateStock(id int, quantity int, operation string) error {
	// Check if spare part exists
	_, err := s.sparePartRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("spare part not found")
	}

	// Validate quantity
	if quantity <= 0 {
		return fmt.Errorf("quantity must be greater than 0")
	}

	// Validate operation
	if operation != "add" && operation != "subtract" {
		return fmt.Errorf("operation must be 'add' or 'subtract'")
	}

	// For subtract operation, check if there's enough stock
	if operation == "subtract" {
		available, err := s.sparePartRepo.CheckStockAvailability(id, quantity)
		if err != nil {
			return fmt.Errorf("failed to check stock availability: %w", err)
		}
		if !available {
			return fmt.Errorf("insufficient stock")
		}
	}

	// Update stock
	err = s.sparePartRepo.UpdateStock(id, quantity, operation)
	if err != nil {
		return fmt.Errorf("failed to update stock: %w", err)
	}

	return nil
}

func (s *sparePartService) GetLowStockItems(page, limit int) ([]models.SparePart, int64, error) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	spareParts, total, err := s.sparePartRepo.GetLowStockItems(page, limit)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get low stock items: %w", err)
	}

	return spareParts, total, nil
}

func (s *sparePartService) CheckStockAvailability(id int, requestedQuantity int) (bool, error) {
	if requestedQuantity <= 0 {
		return false, fmt.Errorf("requested quantity must be greater than 0")
	}

	available, err := s.sparePartRepo.CheckStockAvailability(id, requestedQuantity)
	if err != nil {
		return false, fmt.Errorf("failed to check stock availability: %w", err)
	}

	return available, nil
}

func (s *sparePartService) BulkUpdateStock(updates []models.SparePartStockUpdate) error {
	if len(updates) == 0 {
		return fmt.Errorf("no updates provided")
	}

	// Validate all updates before processing
	for i, update := range updates {
		if update.Quantity <= 0 {
			return fmt.Errorf("quantity must be greater than 0 for update %d", i+1)
		}
		if update.Operation != "add" && update.Operation != "subtract" {
			return fmt.Errorf("operation must be 'add' or 'subtract' for update %d", i+1)
		}

		// For subtract operations, check stock availability
		if update.Operation == "subtract" {
			available, err := s.sparePartRepo.CheckStockAvailability(i+1, update.Quantity) // This would need to be the actual ID
			if err != nil {
				return fmt.Errorf("failed to check stock availability for update %d: %w", i+1, err)
			}
			if !available {
				return fmt.Errorf("insufficient stock for update %d", i+1)
			}
		}
	}

	// Process bulk update
	err := s.sparePartRepo.BulkUpdateStock(updates)
	if err != nil {
		return fmt.Errorf("failed to process bulk stock update: %w", err)
	}

	return nil
}

func (s *sparePartService) GetCategories() ([]string, error) {
	categories, err := s.sparePartRepo.GetCategories()
	if err != nil {
		return nil, fmt.Errorf("failed to get categories: %w", err)
	}

	return categories, nil
}

// Category management implementations

func (s *sparePartService) GetCategoriesWithPagination(page, limit int, search string) ([]models.CategoryInfo, int64, error) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 50
	}

	categories, total, err := s.sparePartRepo.GetCategoriesWithPagination(page, limit, search)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get categories: %w", err)
	}

	return categories, total, nil
}

func (s *sparePartService) CreateCategory(name, description string) error {
	if strings.TrimSpace(name) == "" {
		return fmt.Errorf("category name cannot be empty")
	}

	err := s.sparePartRepo.CreateCategory(strings.TrimSpace(name), strings.TrimSpace(description))
	if err != nil {
		return fmt.Errorf("failed to create category: %w", err)
	}

	return nil
}

func (s *sparePartService) UpdateCategory(id int, name, description string) error {
	if id <= 0 {
		return fmt.Errorf("invalid category ID")
	}
	if strings.TrimSpace(name) == "" {
		return fmt.Errorf("category name cannot be empty")
	}

	err := s.sparePartRepo.UpdateCategory(id, strings.TrimSpace(name), strings.TrimSpace(description))
	if err != nil {
		return fmt.Errorf("failed to update category: %w", err)
	}

	return nil
}

func (s *sparePartService) DeleteCategory(id int) error {
	if id <= 0 {
		return fmt.Errorf("invalid category ID")
	}

	err := s.sparePartRepo.DeleteCategory(id)
	if err != nil {
		return fmt.Errorf("failed to delete category: %w", err)
	}

	return nil
}

func (s *sparePartService) GetCategoryStats() ([]models.CategoryStats, error) {
	stats, err := s.sparePartRepo.GetCategoryStats()
	if err != nil {
		return nil, fmt.Errorf("failed to get category stats: %w", err)
	}

	return stats, nil
}
