package service

import (
	"fmt"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/internal/repository"
)

type SparePartCategoryService interface {
	Create(req *models.SparePartCategoryCreateRequest) (*models.SparePartCategory, error)
	GetByID(id int) (*models.SparePartCategory, error)
	Update(id int, req *models.SparePartCategoryUpdateRequest) (*models.SparePartCategory, error)
	Delete(id int) error
	List(page, limit int, isActive *bool) ([]models.SparePartCategory, int64, error)
}

type sparePartCategoryService struct {
	repo repository.SparePartCategoryRepository
}

func NewSparePartCategoryService(repo repository.SparePartCategoryRepository) SparePartCategoryService {
	return &sparePartCategoryService{
		repo: repo,
	}
}

func (s *sparePartCategoryService) Create(req *models.SparePartCategoryCreateRequest) (*models.SparePartCategory, error) {
	if req.Name == "" {
		return nil, fmt.Errorf("category name is required")
	}

	return s.repo.Create(req)
}

func (s *sparePartCategoryService) GetByID(id int) (*models.SparePartCategory, error) {
	if id <= 0 {
		return nil, fmt.Errorf("invalid category ID")
	}

	return s.repo.GetByID(id)
}

func (s *sparePartCategoryService) Update(id int, req *models.SparePartCategoryUpdateRequest) (*models.SparePartCategory, error) {
	if id <= 0 {
		return nil, fmt.Errorf("invalid category ID")
	}

	if req.Name != nil && *req.Name == "" {
		return nil, fmt.Errorf("category name cannot be empty")
	}

	return s.repo.Update(id, req)
}

func (s *sparePartCategoryService) Delete(id int) error {
	if id <= 0 {
		return fmt.Errorf("invalid category ID")
	}

	return s.repo.Delete(id)
}

func (s *sparePartCategoryService) List(page, limit int, isActive *bool) ([]models.SparePartCategory, int64, error) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	return s.repo.List(page, limit, isActive)
}
