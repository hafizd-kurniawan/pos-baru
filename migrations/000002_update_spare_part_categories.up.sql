-- Add is_active and updated_at columns to spare_part_categories table
ALTER TABLE spare_part_categories 
ADD COLUMN is_active BOOLEAN DEFAULT true NOT NULL,
ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

-- Create trigger to automatically update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_spare_part_categories_updated_at 
    BEFORE UPDATE ON spare_part_categories 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
