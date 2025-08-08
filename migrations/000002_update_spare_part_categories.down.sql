-- Remove is_active and updated_at columns from spare_part_categories table
DROP TRIGGER IF EXISTS update_spare_part_categories_updated_at ON spare_part_categories;
DROP FUNCTION IF EXISTS update_updated_at_column();

ALTER TABLE spare_part_categories 
DROP COLUMN IF EXISTS is_active,
DROP COLUMN IF EXISTS updated_at;
