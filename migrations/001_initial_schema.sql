-- ===================================
-- ERD SISTEM SHOWROOM KENDARAAN
-- ===================================

-- MASTER DATA TABLES
-- ===================================

-- Table: roles
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL, -- 'admin', 'kasir', 'mekanik'
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    role_id INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(id)
);

-- Table: vehicle_types
CREATE TABLE vehicle_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL, -- 'Motor', 'Mobil'
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: vehicle_brands
CREATE TABLE vehicle_brands (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL, -- 'Honda', 'Yamaha', 'Toyota', etc
    type_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (type_id) REFERENCES vehicle_types(id)
);

-- Table: suppliers
CREATE TABLE suppliers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    contact_person VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: customers
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    id_card_number VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- INVENTORY & SPARE PARTS
-- ===================================

-- Table: spare_parts
CREATE TABLE spare_parts (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    unit VARCHAR(20) NOT NULL, -- 'pcs', 'set', 'liter', etc
    purchase_price DECIMAL(15,2) NOT NULL DEFAULT 0,
    selling_price DECIMAL(15,2) NOT NULL DEFAULT 0,
    stock_quantity INT NOT NULL DEFAULT 0,
    minimum_stock INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- VEHICLES
-- ===================================

-- Create ENUM types for PostgreSQL
CREATE TYPE source_type_enum AS ENUM ('customer', 'supplier');
CREATE TYPE condition_status_enum AS ENUM ('excellent', 'good', 'fair', 'poor', 'needs_repair');
CREATE TYPE vehicle_status_enum AS ENUM ('available', 'in_repair', 'sold', 'reserved');

-- Table: vehicles
CREATE TABLE vehicles (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    brand_id INT NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    color VARCHAR(50),
    engine_capacity VARCHAR(20),
    fuel_type VARCHAR(20), -- 'Bensin', 'Solar', 'Listrik'
    transmission_type VARCHAR(20), -- 'Manual', 'Automatic', 'CVT'
    license_plate VARCHAR(20),
    chassis_number VARCHAR(100),
    engine_number VARCHAR(100),
    odometer INT DEFAULT 0,
    source_type source_type_enum NOT NULL,
    source_id INT, -- customer_id or supplier_id
    purchase_price DECIMAL(15,2) NOT NULL,
    condition_status condition_status_enum NOT NULL,
    status vehicle_status_enum DEFAULT 'available',
    repair_cost DECIMAL(15,2) DEFAULT 0,
    hpp_price DECIMAL(15,2) DEFAULT 0, -- Harga Pokok Penjualan
    selling_price DECIMAL(15,2) DEFAULT 0,
    sold_price DECIMAL(15,2) DEFAULT 0,
    sold_date TIMESTAMP NULL,
    notes TEXT,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (brand_id) REFERENCES vehicle_brands(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Table: vehicle_photos
CREATE TABLE vehicle_photos (
    id SERIAL PRIMARY KEY,
    vehicle_id INT NOT NULL,
    photo_path VARCHAR(255) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    caption VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
);

-- REPAIR SYSTEM
-- ===================================

-- Create ENUM types for repair system
CREATE TYPE repair_status_enum AS ENUM ('pending', 'in_progress', 'completed', 'cancelled');

-- Table: repair_orders
CREATE TABLE repair_orders (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    vehicle_id INT NOT NULL,
    mechanic_id INT NOT NULL,
    assigned_by INT NOT NULL, -- kasir yang assign
    description TEXT,
    estimated_cost DECIMAL(15,2) DEFAULT 0,
    actual_cost DECIMAL(15,2) DEFAULT 0,
    status repair_status_enum DEFAULT 'pending',
    started_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (mechanic_id) REFERENCES users(id),
    FOREIGN KEY (assigned_by) REFERENCES users(id)
);

-- Table: repair_spare_parts
CREATE TABLE repair_spare_parts (
    id SERIAL PRIMARY KEY,
    repair_order_id INT NOT NULL,
    spare_part_id INT NOT NULL,
    quantity_used INT NOT NULL,
    unit_price DECIMAL(15,2) NOT NULL,
    total_price DECIMAL(15,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (repair_order_id) REFERENCES repair_orders(id),
    FOREIGN KEY (spare_part_id) REFERENCES spare_parts(id)
);

-- TRANSACTIONS
-- ===================================

-- Create ENUM types for transactions
CREATE TYPE payment_status_enum AS ENUM ('pending', 'partial', 'paid');

-- Table: purchase_transactions (Pembelian dari customer/supplier)
CREATE TABLE purchase_transactions (
    id SERIAL PRIMARY KEY,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    transaction_date DATE NOT NULL,
    source_type source_type_enum NOT NULL,
    source_id INT NOT NULL, -- customer_id or supplier_id
    vehicle_id INT NOT NULL,
    purchase_price DECIMAL(15,2) NOT NULL,
    payment_method VARCHAR(50), -- 'cash', 'transfer', 'cheque'
    payment_status payment_status_enum DEFAULT 'paid',
    notes TEXT,
    processed_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (processed_by) REFERENCES users(id)
);

-- Table: sales_transactions (Penjualan ke customer)
CREATE TABLE sales_transactions (
    id SERIAL PRIMARY KEY,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    transaction_date DATE NOT NULL,
    customer_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    hpp_price DECIMAL(15,2) NOT NULL,
    selling_price DECIMAL(15,2) NOT NULL,
    profit DECIMAL(15,2) NOT NULL,
    payment_method VARCHAR(50), -- 'cash', 'transfer', 'credit'
    payment_status payment_status_enum DEFAULT 'pending',
    down_payment DECIMAL(15,2) DEFAULT 0,
    remaining_payment DECIMAL(15,2) DEFAULT 0,
    notes TEXT,
    processed_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (processed_by) REFERENCES users(id)
);

-- FINANCIAL CLOSING
-- ===================================

-- Table: daily_closings
CREATE TABLE daily_closings (
    id SERIAL PRIMARY KEY,
    closing_date DATE UNIQUE NOT NULL,
    total_purchase DECIMAL(15,2) DEFAULT 0,
    total_sales DECIMAL(15,2) DEFAULT 0,
    total_repair_cost DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    cash_in_hand DECIMAL(15,2) DEFAULT 0,
    notes TEXT,
    closed_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (closed_by) REFERENCES users(id)
);

-- Table: monthly_closings
CREATE TABLE monthly_closings (
    id SERIAL PRIMARY KEY,
    month INT NOT NULL,
    year INT NOT NULL,
    total_purchase DECIMAL(15,2) DEFAULT 0,
    total_sales DECIMAL(15,2) DEFAULT 0,
    total_repair_cost DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    vehicles_purchased INT DEFAULT 0,
    vehicles_sold INT DEFAULT 0,
    vehicles_in_stock INT DEFAULT 0,
    closed_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (month, year),
    FOREIGN KEY (closed_by) REFERENCES users(id)
);

-- DASHBOARD & REPORTING
-- ===================================

-- Table: dashboard_metrics (untuk caching data dashboard)
CREATE TABLE dashboard_metrics (
    id SERIAL PRIMARY KEY,
    metric_date DATE NOT NULL,
    vehicles_available INT DEFAULT 0,
    vehicles_in_repair INT DEFAULT 0,
    vehicles_sold_today INT DEFAULT 0,
    revenue_today DECIMAL(15,2) DEFAULT 0,
    profit_today DECIMAL(15,2) DEFAULT 0,
    pending_repairs INT DEFAULT 0,
    low_stock_items INT DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (metric_date)
);

-- ===================================
-- INDEXES FOR PERFORMANCE
-- ===================================

-- Vehicles indexes
CREATE INDEX idx_vehicles_status ON vehicles(status);
CREATE INDEX idx_vehicles_source ON vehicles(source_type, source_id);
CREATE INDEX idx_vehicles_brand ON vehicles(brand_id);

-- Transactions indexes
CREATE INDEX idx_purchase_date ON purchase_transactions(transaction_date);
CREATE INDEX idx_sales_date ON sales_transactions(transaction_date);
CREATE INDEX idx_purchase_source ON purchase_transactions(source_type, source_id);

-- Repair orders indexes
CREATE INDEX idx_repair_status ON repair_orders(status);
CREATE INDEX idx_repair_mechanic ON repair_orders(mechanic_id);
CREATE INDEX idx_repair_vehicle ON repair_orders(vehicle_id);

-- Dashboard metrics index
CREATE INDEX idx_metrics_date ON dashboard_metrics(metric_date);

-- ===================================
-- SAMPLE DATA
-- ===================================

-- Insert roles
INSERT INTO roles (name, description) VALUES 
('admin', 'Administrator dengan akses penuh'),
('kasir', 'Kasir untuk transaksi dan assign mekanik'),
('mekanik', 'Mekanik untuk perbaikan kendaraan');

-- Insert vehicle types
INSERT INTO vehicle_types (name, description) VALUES 
('Motor', 'Kendaraan roda dua'),
('Mobil', 'Kendaraan roda empat');

-- Insert sample brands
INSERT INTO vehicle_brands (name, type_id) VALUES 
('Honda', 1), ('Yamaha', 1), ('Suzuki', 1),
('Toyota', 2), ('Honda', 2), ('Suzuki', 2);

-- Insert default admin user (password: admin123)
INSERT INTO users (username, email, password, full_name, phone, role_id) VALUES 
('admin', 'admin@showroom.com', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8KzCzFONZOEu.tA1U8Y7Uj7nJ7P8/K', 'System Administrator', '081234567890', 1);

-- Insert sample customers
INSERT INTO customers (name, phone, email, address, id_card_number) VALUES 
('Budi Santoso', '081234567891', 'budi@email.com', 'Jl. Merdeka No. 123, Jakarta', '3101234567891234'),
('Siti Aminah', '081234567892', 'siti@email.com', 'Jl. Sudirman No. 456, Jakarta', '3101234567892345'),
('Agus Wijaya', '081234567893', 'agus@email.com', 'Jl. Thamrin No. 789, Jakarta', '3101234567893456'),
('Maya Sari', '081234567894', 'maya@email.com', 'Jl. Gatot Subroto No. 101, Jakarta', '3101234567894567'),
('Rudi Hartono', '081234567895', 'rudi@email.com', 'Jl. Kuningan No. 202, Jakarta', '3101234567895678');

-- Insert sample suppliers
INSERT INTO suppliers (name, contact_person, phone, email, address, is_active) VALUES 
('CV Motor Jaya', 'Pak Joko', '021-12345678', 'info@motorjaya.com', 'Jl. Industri No. 45, Jakarta', true),
('PT Mobil Sentosa', 'Bu Rina', '021-87654321', 'contact@mobilsentosa.com', 'Jl. Otomotif No. 67, Bekasi', true),
('UD Spare Part Center', 'Pak Andi', '021-11223344', 'sales@sparepartcenter.com', 'Jl. Perdagangan No. 89, Tangerang', true);