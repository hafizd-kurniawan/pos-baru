package repository

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/jmoiron/sqlx"

	"github.com/hafizd-kurniawan/pos-baru/internal/domain/models"
	"github.com/hafizd-kurniawan/pos-baru/pkg/database"
)

type RepairRepository interface {
	Create(repair *models.RepairOrder) error
	GetByID(id int) (*models.RepairOrder, error)
	GetByCode(code string) (*models.RepairOrder, error)
	List(filter models.RepairOrderFilter, page, limit int) ([]models.RepairOrder, int, error)
	Update(id int, updates *models.RepairOrderUpdateRequest) error
	UpdateProgress(id int, progress *models.RepairProgressUpdateRequest) error
	Delete(id int) error
	
	// Spare parts in repair
	AddSparePart(repairID int, sparePart *models.RepairSparePartCreateRequest) error
	RemoveSparePart(repairID int, sparePartID int) error
	GetSpareParts(repairID int) ([]models.RepairSparePart, error)
	
	// Statistics
	GetRepairStats(mechanicID *int, dateFrom, dateTo *time.Time) (map[string]interface{}, error)
}

type repairRepository struct {
	db *database.Database
}

func NewRepairRepository(db *database.Database) RepairRepository {
	return &repairRepository{db: db}
}

func (r *repairRepository) Create(repair *models.RepairOrder) error {
	query := `
		INSERT INTO repair_orders (code, vehicle_id, mechanic_id, assigned_by, description, estimated_cost, status, notes)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, created_at, updated_at`
	
	return r.db.QueryRow(query, repair.Code, repair.VehicleID, repair.MechanicID, repair.AssignedBy, 
		repair.Description, repair.EstimatedCost, repair.Status, repair.Notes).
		Scan(&repair.ID, &repair.CreatedAt, &repair.UpdatedAt)
}

func (r *repairRepository) GetByID(id int) (*models.RepairOrder, error) {
	repair := &models.RepairOrder{}
	query := `
		SELECT ro.id, ro.code, ro.vehicle_id, ro.mechanic_id, ro.assigned_by, ro.description,
			   ro.estimated_cost, ro.actual_cost, ro.status, ro.started_at, ro.completed_at,
			   ro.notes, ro.created_at, ro.updated_at,
			   v.id, v.code, v.model, v.year, v.color, v.license_plate, v.status,
			   m.id, m.username, m.full_name,
			   a.id, a.username, a.full_name
		FROM repair_orders ro
		LEFT JOIN vehicles v ON ro.vehicle_id = v.id
		LEFT JOIN users m ON ro.mechanic_id = m.id
		LEFT JOIN users a ON ro.assigned_by = a.id
		WHERE ro.id = $1`
	
	rows, err := r.db.Query(query, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	
	if rows.Next() {
		var vehicle models.Vehicle
		var mechanic models.User
		var assigner models.User
		
		err := rows.Scan(
			&repair.ID, &repair.Code, &repair.VehicleID, &repair.MechanicID, &repair.AssignedBy,
			&repair.Description, &repair.EstimatedCost, &repair.ActualCost, &repair.Status,
			&repair.StartedAt, &repair.CompletedAt, &repair.Notes, &repair.CreatedAt, &repair.UpdatedAt,
			&vehicle.ID, &vehicle.Code, &vehicle.Model, &vehicle.Year, &vehicle.Color,
			&vehicle.LicensePlate, &vehicle.Status,
			&mechanic.ID, &mechanic.Username, &mechanic.FullName,
			&assigner.ID, &assigner.Username, &assigner.FullName,
		)
		if err != nil {
			return nil, err
		}
		
		repair.Vehicle = &vehicle
		repair.Mechanic = &mechanic
		repair.Assigner = &assigner
		
		// Load spare parts
		spareParts, err := r.GetSpareParts(repair.ID)
		if err != nil {
			return nil, err
		}
		repair.SpareParts = spareParts
		
		return repair, nil
	}
	
	return nil, sql.ErrNoRows
}

func (r *repairRepository) GetByCode(code string) (*models.RepairOrder, error) {
	repair := &models.RepairOrder{}
	query := `
		SELECT id, code, vehicle_id, mechanic_id, assigned_by, description,
			   estimated_cost, actual_cost, status, started_at, completed_at,
			   notes, created_at, updated_at
		FROM repair_orders
		WHERE code = $1`
	
	err := r.db.Get(repair, query, code)
	if err != nil {
		return nil, err
	}
	
	return repair, nil
}

func (r *repairRepository) List(filter models.RepairOrderFilter, page, limit int) ([]models.RepairOrder, int, error) {
	var conditions []string
	var args []interface{}
	argIndex := 1
	
	// Build WHERE conditions
	if filter.Status != "" {
		conditions = append(conditions, fmt.Sprintf("ro.status = $%d", argIndex))
		args = append(args, filter.Status)
		argIndex++
	}
	
	if filter.MechanicID > 0 {
		conditions = append(conditions, fmt.Sprintf("ro.mechanic_id = $%d", argIndex))
		args = append(args, filter.MechanicID)
		argIndex++
	}
	
	if filter.VehicleID > 0 {
		conditions = append(conditions, fmt.Sprintf("ro.vehicle_id = $%d", argIndex))
		args = append(args, filter.VehicleID)
		argIndex++
	}
	
	if filter.DateFrom != "" {
		conditions = append(conditions, fmt.Sprintf("ro.created_at >= $%d", argIndex))
		args = append(args, filter.DateFrom)
		argIndex++
	}
	
	if filter.DateTo != "" {
		conditions = append(conditions, fmt.Sprintf("ro.created_at <= $%d", argIndex))
		args = append(args, filter.DateTo)
		argIndex++
	}
	
	// Build WHERE clause
	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}
	
	// Count total records
	countQuery := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM repair_orders ro
		%s`, whereClause)
	
	var total int
	err := r.db.Get(&total, countQuery, args...)
	if err != nil {
		return nil, 0, err
	}
	
	// Get paginated results
	offset := (page - 1) * limit
	
	query := fmt.Sprintf(`
		SELECT ro.id, ro.code, ro.vehicle_id, ro.mechanic_id, ro.assigned_by,
			   ro.description, ro.estimated_cost, ro.actual_cost, ro.status,
			   ro.started_at, ro.completed_at, ro.notes, ro.created_at, ro.updated_at,
			   v.code as vehicle_code, v.model, v.year, v.color, v.license_plate,
			   m.username as mechanic_username, m.full_name as mechanic_name,
			   a.username as assigner_username, a.full_name as assigner_name
		FROM repair_orders ro
		LEFT JOIN vehicles v ON ro.vehicle_id = v.id
		LEFT JOIN users m ON ro.mechanic_id = m.id
		LEFT JOIN users a ON ro.assigned_by = a.id
		%s
		ORDER BY ro.created_at DESC
		LIMIT $%d OFFSET $%d`, whereClause, argIndex, argIndex+1)
	
	args = append(args, limit, offset)
	
	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	
	var repairs []models.RepairOrder
	
	for rows.Next() {
		var repair models.RepairOrder
		var vehicleCode, vehicleModel, vehicleColor, vehiclePlate sql.NullString
		var vehicleYear sql.NullInt32
		var mechanicUsername, mechanicName, assignerUsername, assignerName sql.NullString
		
		err := rows.Scan(
			&repair.ID, &repair.Code, &repair.VehicleID, &repair.MechanicID, &repair.AssignedBy,
			&repair.Description, &repair.EstimatedCost, &repair.ActualCost, &repair.Status,
			&repair.StartedAt, &repair.CompletedAt, &repair.Notes, &repair.CreatedAt, &repair.UpdatedAt,
			&vehicleCode, &vehicleModel, &vehicleYear, &vehicleColor, &vehiclePlate,
			&mechanicUsername, &mechanicName,
			&assignerUsername, &assignerName,
		)
		if err != nil {
			return nil, 0, err
		}
		
		// Set vehicle info if available
		if vehicleCode.Valid {
			repair.Vehicle = &models.Vehicle{
				ID:           repair.VehicleID,
				Code:         vehicleCode.String,
				Model:        vehicleModel.String,
				Year:         int(vehicleYear.Int32),
				Color:        &vehicleColor.String,
				LicensePlate: &vehiclePlate.String,
			}
		}
		
		// Set mechanic info if available
		if mechanicUsername.Valid {
			repair.Mechanic = &models.User{
				ID:       repair.MechanicID,
				Username: mechanicUsername.String,
				FullName: mechanicName.String,
			}
		}
		
		// Set assigner info if available
		if assignerUsername.Valid {
			repair.Assigner = &models.User{
				ID:       repair.AssignedBy,
				Username: assignerUsername.String,
				FullName: assignerName.String,
			}
		}
		
		repairs = append(repairs, repair)
	}
	
	return repairs, total, nil
}

func (r *repairRepository) Update(id int, updates *models.RepairOrderUpdateRequest) error {
	var setParts []string
	var args []interface{}
	argIndex := 1
	
	if updates.Description != nil {
		setParts = append(setParts, fmt.Sprintf("description = $%d", argIndex))
		args = append(args, *updates.Description)
		argIndex++
	}
	
	if updates.EstimatedCost != nil {
		setParts = append(setParts, fmt.Sprintf("estimated_cost = $%d", argIndex))
		args = append(args, *updates.EstimatedCost)
		argIndex++
	}
	
	if updates.ActualCost != nil {
		setParts = append(setParts, fmt.Sprintf("actual_cost = $%d", argIndex))
		args = append(args, *updates.ActualCost)
		argIndex++
	}
	
	if updates.Status != nil {
		setParts = append(setParts, fmt.Sprintf("status = $%d", argIndex))
		args = append(args, *updates.Status)
		argIndex++
		
		// Set started_at if status is in_progress and not already set
		if *updates.Status == models.RepairStatusInProgress {
			setParts = append(setParts, fmt.Sprintf("started_at = CASE WHEN started_at IS NULL THEN NOW() ELSE started_at END"))
		}
		
		// Set completed_at if status is completed
		if *updates.Status == models.RepairStatusCompleted {
			setParts = append(setParts, fmt.Sprintf("completed_at = NOW()"))
		}
	}
	
	if updates.Notes != nil {
		setParts = append(setParts, fmt.Sprintf("notes = $%d", argIndex))
		args = append(args, *updates.Notes)
		argIndex++
	}
	
	if len(setParts) == 0 {
		return nil // Nothing to update
	}
	
	setParts = append(setParts, "updated_at = NOW()")
	
	query := fmt.Sprintf(`
		UPDATE repair_orders 
		SET %s
		WHERE id = $%d`, strings.Join(setParts, ", "), argIndex)
	
	args = append(args, id)
	
	result, err := r.db.Exec(query, args...)
	if err != nil {
		return err
	}
	
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}
	
	if rowsAffected == 0 {
		return sql.ErrNoRows
	}
	
	return nil
}

func (r *repairRepository) UpdateProgress(id int, progress *models.RepairProgressUpdateRequest) error {
	tx, err := r.db.Beginx()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	
	// Update repair order
	var setParts []string
	var args []interface{}
	argIndex := 1
	
	setParts = append(setParts, fmt.Sprintf("status = $%d", argIndex))
	args = append(args, progress.Status)
	argIndex++
	
	if progress.ActualCost != nil {
		setParts = append(setParts, fmt.Sprintf("actual_cost = $%d", argIndex))
		args = append(args, *progress.ActualCost)
		argIndex++
	}
	
	if progress.Notes != nil {
		setParts = append(setParts, fmt.Sprintf("notes = $%d", argIndex))
		args = append(args, *progress.Notes)
		argIndex++
	}
	
	// Set timestamps based on status
	if progress.Status == models.RepairStatusInProgress {
		setParts = append(setParts, "started_at = CASE WHEN started_at IS NULL THEN NOW() ELSE started_at END")
	} else if progress.Status == models.RepairStatusCompleted {
		setParts = append(setParts, "completed_at = NOW()")
	}
	
	setParts = append(setParts, "updated_at = NOW()")
	
	query := fmt.Sprintf(`
		UPDATE repair_orders 
		SET %s
		WHERE id = $%d`, strings.Join(setParts, ", "), argIndex)
	
	args = append(args, id)
	
	_, err = tx.Exec(query, args...)
	if err != nil {
		return err
	}
	
	// Add spare parts if provided
	for _, sp := range progress.SpareParts {
		err = r.addSparePartTx(tx, id, &sp)
		if err != nil {
			return err
		}
	}
	
	return tx.Commit()
}

func (r *repairRepository) Delete(id int) error {
	query := `DELETE FROM repair_orders WHERE id = $1`
	result, err := r.db.Exec(query, id)
	if err != nil {
		return err
	}
	
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}
	
	if rowsAffected == 0 {
		return sql.ErrNoRows
	}
	
	return nil
}

func (r *repairRepository) AddSparePart(repairID int, sparePart *models.RepairSparePartCreateRequest) error {
	tx, err := r.db.Beginx()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	
	err = r.addSparePartTx(tx, repairID, sparePart)
	if err != nil {
		return err
	}
	
	return tx.Commit()
}

func (r *repairRepository) addSparePartTx(tx *sqlx.Tx, repairID int, sparePart *models.RepairSparePartCreateRequest) error {
	// Get spare part details and check stock
	var unitPrice float64
	var currentStock int
	query := `SELECT selling_price, stock_quantity FROM spare_parts WHERE id = $1`
	err := tx.QueryRow(query, sparePart.SparePartID).Scan(&unitPrice, &currentStock)
	if err != nil {
		return err
	}
	
	// Check if enough stock
	if currentStock < sparePart.QuantityUsed {
		return fmt.Errorf("insufficient stock: available %d, required %d", currentStock, sparePart.QuantityUsed)
	}
	
	// Calculate total price
	totalPrice := unitPrice * float64(sparePart.QuantityUsed)
	
	// Insert repair spare part
	query = `
		INSERT INTO repair_spare_parts (repair_order_id, spare_part_id, quantity_used, unit_price, total_price)
		VALUES ($1, $2, $3, $4, $5)`
	
	_, err = tx.Exec(query, repairID, sparePart.SparePartID, sparePart.QuantityUsed, unitPrice, totalPrice)
	if err != nil {
		return err
	}
	
	// Update spare part stock
	query = `UPDATE spare_parts SET stock_quantity = stock_quantity - $1 WHERE id = $2`
	_, err = tx.Exec(query, sparePart.QuantityUsed, sparePart.SparePartID)
	if err != nil {
		return err
	}
	
	return nil
}

func (r *repairRepository) RemoveSparePart(repairID int, sparePartID int) error {
	tx, err := r.db.Beginx()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	
	// Get quantity used to restore stock
	var quantityUsed int
	query := `SELECT quantity_used FROM repair_spare_parts WHERE repair_order_id = $1 AND spare_part_id = $2`
	err = tx.QueryRow(query, repairID, sparePartID).Scan(&quantityUsed)
	if err != nil {
		return err
	}
	
	// Delete repair spare part record
	query = `DELETE FROM repair_spare_parts WHERE repair_order_id = $1 AND spare_part_id = $2`
	_, err = tx.Exec(query, repairID, sparePartID)
	if err != nil {
		return err
	}
	
	// Restore spare part stock
	query = `UPDATE spare_parts SET stock_quantity = stock_quantity + $1 WHERE id = $2`
	_, err = tx.Exec(query, quantityUsed, sparePartID)
	if err != nil {
		return err
	}
	
	return tx.Commit()
}

func (r *repairRepository) GetSpareParts(repairID int) ([]models.RepairSparePart, error) {
	query := `
		SELECT rsp.id, rsp.repair_order_id, rsp.spare_part_id, rsp.quantity_used,
			   rsp.unit_price, rsp.total_price, rsp.created_at,
			   sp.code, sp.name, sp.unit
		FROM repair_spare_parts rsp
		LEFT JOIN spare_parts sp ON rsp.spare_part_id = sp.id
		WHERE rsp.repair_order_id = $1
		ORDER BY rsp.created_at`
	
	rows, err := r.db.Query(query, repairID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	
	var spareParts []models.RepairSparePart
	
	for rows.Next() {
		var rsp models.RepairSparePart
		var sparePartCode, sparePartName, sparePartUnit sql.NullString
		
		err := rows.Scan(
			&rsp.ID, &rsp.RepairOrderID, &rsp.SparePartID, &rsp.QuantityUsed,
			&rsp.UnitPrice, &rsp.TotalPrice, &rsp.CreatedAt,
			&sparePartCode, &sparePartName, &sparePartUnit,
		)
		if err != nil {
			return nil, err
		}
		
		if sparePartCode.Valid {
			rsp.SparePart = &models.SparePart{
				ID:   rsp.SparePartID,
				Code: sparePartCode.String,
				Name: sparePartName.String,
				Unit: sparePartUnit.String,
			}
		}
		
		spareParts = append(spareParts, rsp)
	}
	
	return spareParts, nil
}

func (r *repairRepository) GetRepairStats(mechanicID *int, dateFrom, dateTo *time.Time) (map[string]interface{}, error) {
	var conditions []string
	var args []interface{}
	argIndex := 1
	
	if mechanicID != nil {
		conditions = append(conditions, fmt.Sprintf("mechanic_id = $%d", argIndex))
		args = append(args, *mechanicID)
		argIndex++
	}
	
	if dateFrom != nil {
		conditions = append(conditions, fmt.Sprintf("created_at >= $%d", argIndex))
		args = append(args, *dateFrom)
		argIndex++
	}
	
	if dateTo != nil {
		conditions = append(conditions, fmt.Sprintf("created_at <= $%d", argIndex))
		args = append(args, *dateTo)
		argIndex++
	}
	
	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}
	
	query := fmt.Sprintf(`
		SELECT 
			COUNT(*) as total_repairs,
			COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_repairs,
			COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as in_progress_repairs,
			COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_repairs,
			COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_repairs,
			COALESCE(SUM(estimated_cost), 0) as total_estimated_cost,
			COALESCE(SUM(actual_cost), 0) as total_actual_cost,
			COALESCE(AVG(CASE WHEN completed_at IS NOT NULL AND started_at IS NOT NULL 
				THEN EXTRACT(EPOCH FROM (completed_at - started_at))/3600 END), 0) as avg_completion_hours
		FROM repair_orders
		%s`, whereClause)
	
	var stats map[string]interface{} = make(map[string]interface{})
	var totalRepairs, pending, inProgress, completed, cancelled int
	var totalEstimated, totalActual, avgHours float64
	
	err := r.db.QueryRow(query, args...).Scan(
		&totalRepairs, &pending, &inProgress, &completed, &cancelled,
		&totalEstimated, &totalActual, &avgHours,
	)
	if err != nil {
		return nil, err
	}
	
	stats["total_repairs"] = totalRepairs
	stats["pending_repairs"] = pending
	stats["in_progress_repairs"] = inProgress
	stats["completed_repairs"] = completed
	stats["cancelled_repairs"] = cancelled
	stats["total_estimated_cost"] = totalEstimated
	stats["total_actual_cost"] = totalActual
	stats["average_completion_hours"] = avgHours
	
	return stats, nil
}