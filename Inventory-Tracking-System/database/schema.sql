-- ============================================
-- Multi-Warehouse Inventory Management System
-- Author: Kevin Beita Marín
-- Description: Database schema with audit triggers and automation
-- ============================================

-- Drop existing database if exists
DROP DATABASE IF EXISTS inventory_system;
CREATE DATABASE inventory_system;
USE inventory_system;

-- ============================================
-- CORE TABLES
-- ============================================

-- Warehouses Table
CREATE TABLE warehouses (
    warehouse_id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_name VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    manager_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    capacity INT NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_warehouse_name (warehouse_name),
    INDEX idx_location (location),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Product Categories Table
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_category_id INT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    INDEX idx_category_name (category_name),
    INDEX idx_parent_category (parent_category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Products Table
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_code VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id INT NOT NULL,
    unit_of_measure VARCHAR(20) NOT NULL DEFAULT 'unit',
    unit_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    reorder_level INT NOT NULL DEFAULT 10,
    minimum_stock INT NOT NULL DEFAULT 5,
    maximum_stock INT NOT NULL DEFAULT 1000,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
    INDEX idx_product_code (product_code),
    INDEX idx_product_name (product_name),
    INDEX idx_category (category_id),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Inventory Table (Current Stock per Warehouse)
CREATE TABLE inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_on_hand INT NOT NULL DEFAULT 0,
    quantity_reserved INT NOT NULL DEFAULT 0,
    quantity_available INT GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) STORED,
    last_stock_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    UNIQUE KEY unique_warehouse_product (warehouse_id, product_id),
    INDEX idx_warehouse (warehouse_id),
    INDEX idx_product (product_id),
    INDEX idx_quantity_available (quantity_available),
    CONSTRAINT chk_quantity_positive CHECK (quantity_on_hand >= 0),
    CONSTRAINT chk_reserved_positive CHECK (quantity_reserved >= 0),
    CONSTRAINT chk_reserved_not_exceed CHECK (quantity_reserved <= quantity_on_hand)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Stock Movement Types
CREATE TABLE movement_types (
    movement_type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_code VARCHAR(20) NOT NULL UNIQUE,
    type_name VARCHAR(50) NOT NULL,
    description TEXT,
    affects_stock ENUM('IN', 'OUT', 'TRANSFER') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type_code (type_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Stock Movements Table
CREATE TABLE stock_movements (
    movement_id INT AUTO_INCREMENT PRIMARY KEY,
    movement_type_id INT NOT NULL,
    product_id INT NOT NULL,
    from_warehouse_id INT NULL,
    to_warehouse_id INT NULL,
    quantity INT NOT NULL,
    unit_cost DECIMAL(10, 2) DEFAULT 0.00,
    total_cost DECIMAL(12, 2) GENERATED ALWAYS AS (quantity * unit_cost) STORED,
    reference_number VARCHAR(100),
    notes TEXT,
    movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (movement_type_id) REFERENCES movement_types(movement_type_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
    FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE RESTRICT,
    FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE RESTRICT,
    INDEX idx_movement_type (movement_type_id),
    INDEX idx_product (product_id),
    INDEX idx_from_warehouse (from_warehouse_id),
    INDEX idx_to_warehouse (to_warehouse_id),
    INDEX idx_movement_date (movement_date),
    INDEX idx_reference (reference_number),
    CONSTRAINT chk_quantity_movement_positive CHECK (quantity > 0),
    CONSTRAINT chk_warehouse_different CHECK (
        from_warehouse_id IS NULL OR 
        to_warehouse_id IS NULL OR 
        from_warehouse_id != to_warehouse_id
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- AUDIT TABLES
-- ============================================

-- Audit Trail for Inventory Changes
CREATE TABLE inventory_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    inventory_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    old_quantity INT,
    new_quantity INT,
    quantity_change INT,
    old_reserved INT,
    new_reserved INT,
    change_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    INDEX idx_inventory (inventory_id),
    INDEX idx_warehouse (warehouse_id),
    INDEX idx_product (product_id),
    INDEX idx_changed_at (changed_at),
    INDEX idx_change_type (change_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Audit Trail for Stock Movements
CREATE TABLE movement_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    movement_id INT NOT NULL,
    action_type ENUM('CREATED', 'UPDATED', 'DELETED', 'CANCELLED') NOT NULL,
    old_data JSON,
    new_data JSON,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    notes TEXT,
    INDEX idx_movement (movement_id),
    INDEX idx_action_type (action_type),
    INDEX idx_changed_at (changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- REPORTING & ANALYTICS TABLES
-- ============================================

-- Stock Alerts (Low Stock, Overstock, etc.)
CREATE TABLE stock_alerts (
    alert_id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    alert_type ENUM('LOW_STOCK', 'OUT_OF_STOCK', 'OVERSTOCK', 'EXPIRING_SOON') NOT NULL,
    current_quantity INT NOT NULL,
    threshold_quantity INT,
    alert_status ENUM('OPEN', 'ACKNOWLEDGED', 'RESOLVED') DEFAULT 'OPEN',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMP NULL,
    resolved_at TIMESTAMP NULL,
    notes TEXT,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    INDEX idx_warehouse (warehouse_id),
    INDEX idx_product (product_id),
    INDEX idx_alert_type (alert_type),
    INDEX idx_alert_status (alert_status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Inventory Snapshot (for historical reporting)
CREATE TABLE inventory_snapshots (
    snapshot_id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_on_hand INT NOT NULL,
    quantity_reserved INT NOT NULL,
    quantity_available INT NOT NULL,
    snapshot_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    UNIQUE KEY unique_snapshot (warehouse_id, product_id, snapshot_date),
    INDEX idx_snapshot_date (snapshot_date),
    INDEX idx_warehouse (warehouse_id),
    INDEX idx_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- USERS & PERMISSIONS (Basic)
-- ============================================

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('ADMIN', 'MANAGER', 'OPERATOR', 'VIEWER') DEFAULT 'VIEWER',
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

-- View: Current Inventory Status
CREATE OR REPLACE VIEW v_inventory_status AS
SELECT 
    i.inventory_id,
    w.warehouse_name,
    w.location,
    p.product_code,
    p.product_name,
    c.category_name,
    i.quantity_on_hand,
    i.quantity_reserved,
    i.quantity_available,
    p.reorder_level,
    p.minimum_stock,
    p.unit_price,
    (i.quantity_available * p.unit_price) AS inventory_value,
    CASE 
        WHEN i.quantity_available <= 0 THEN 'OUT_OF_STOCK'
        WHEN i.quantity_available <= p.minimum_stock THEN 'CRITICAL'
        WHEN i.quantity_available <= p.reorder_level THEN 'LOW'
        ELSE 'NORMAL'
    END AS stock_status,
    i.last_stock_date
FROM inventory i
INNER JOIN warehouses w ON i.warehouse_id = w.warehouse_id
INNER JOIN products p ON i.product_id = p.product_id
INNER JOIN categories c ON p.category_id = c.category_id
WHERE w.is_active = TRUE AND p.is_active = TRUE;

-- View: Stock Movement Summary
CREATE OR REPLACE VIEW v_stock_movement_summary AS
SELECT 
    sm.movement_id,
    mt.type_name AS movement_type,
    mt.affects_stock,
    p.product_code,
    p.product_name,
    wf.warehouse_name AS from_warehouse,
    wt.warehouse_name AS to_warehouse,
    sm.quantity,
    sm.unit_cost,
    sm.total_cost,
    sm.reference_number,
    sm.movement_date,
    sm.created_by
FROM stock_movements sm
INNER JOIN movement_types mt ON sm.movement_type_id = mt.movement_type_id
INNER JOIN products p ON sm.product_id = p.product_id
LEFT JOIN warehouses wf ON sm.from_warehouse_id = wf.warehouse_id
LEFT JOIN warehouses wt ON sm.to_warehouse_id = wt.warehouse_id
ORDER BY sm.movement_date DESC;

-- View: Products Needing Reorder
CREATE OR REPLACE VIEW v_products_to_reorder AS
SELECT 
    w.warehouse_name,
    p.product_code,
    p.product_name,
    i.quantity_available,
    p.reorder_level,
    p.minimum_stock,
    (p.reorder_level - i.quantity_available) AS quantity_to_order
FROM inventory i
INNER JOIN warehouses w ON i.warehouse_id = w.warehouse_id
INNER JOIN products p ON i.product_id = p.product_id
WHERE i.quantity_available <= p.reorder_level
  AND w.is_active = TRUE
  AND p.is_active = TRUE
ORDER BY i.quantity_available ASC;

-- ============================================
-- PERFORMANCE OPTIMIZATION
-- ============================================

-- Composite indexes for common query patterns
CREATE INDEX idx_inventory_warehouse_product_qty ON inventory(warehouse_id, product_id, quantity_available);
CREATE INDEX idx_movements_date_type ON stock_movements(movement_date, movement_type_id);
CREATE INDEX idx_movements_product_date ON stock_movements(product_id, movement_date);

-- Full-text search index for products
ALTER TABLE products ADD FULLTEXT INDEX ft_product_search(product_name, description);

-- ============================================
-- COMMENTS
-- ============================================

-- Add table comments
ALTER TABLE warehouses COMMENT = 'Stores information about physical warehouse locations';
ALTER TABLE products COMMENT = 'Product master data with pricing and stock level thresholds';
ALTER TABLE inventory COMMENT = 'Current stock levels per warehouse with computed available quantity';
ALTER TABLE stock_movements COMMENT = 'All stock movements (IN, OUT, TRANSFER) with audit trail';
ALTER TABLE inventory_audit COMMENT = 'Complete audit log of all inventory changes';