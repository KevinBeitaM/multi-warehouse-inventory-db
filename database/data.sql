-- ============================================
-- SAMPLE DATA FOR TESTING
-- Author: Kevin Beita Marín
-- Description: Realistic test data for inventory system
-- ============================================

USE inventory_system;

-- Disable foreign key checks for data loading
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- MOVEMENT TYPES
-- ============================================

INSERT INTO movement_types (type_code, type_name, description, affects_stock) VALUES
('PURCHASE', 'Purchase Order', 'Stock received from supplier', 'IN'),
('SALE', 'Sales Order', 'Stock sold to customer', 'OUT'),
('RETURN_IN', 'Customer Return', 'Stock returned by customer', 'IN'),
('RETURN_OUT', 'Supplier Return', 'Stock returned to supplier', 'OUT'),
('TRANSFER', 'Warehouse Transfer', 'Stock moved between warehouses', 'TRANSFER'),
('ADJUSTMENT', 'Inventory Adjustment', 'Manual stock correction', 'IN'),
('DAMAGE', 'Damaged Goods', 'Stock written off due to damage', 'OUT'),
('PRODUCTION', 'Production Input', 'Stock used in production', 'OUT'),
('ASSEMBLY', 'Assembly Output', 'Finished goods from assembly', 'IN');

-- ============================================
-- WAREHOUSES
-- ============================================

INSERT INTO warehouses (warehouse_name, location, manager_name, phone, email, capacity) VALUES
('Main Warehouse - North', 'New York, NY 10001', 'John Smith', '+1-555-0101', 'john.smith@inventory.com', 50000),
('Distribution Center - South', 'Miami, FL 33101', 'Maria Garcia', '+1-555-0102', 'maria.garcia@inventory.com', 35000),
('Regional Hub - West', 'Los Angeles, CA 90001', 'David Chen', '+1-555-0103', 'david.chen@inventory.com', 40000),
('Distribution Center - Central', 'Chicago, IL 60601', 'Sarah Johnson', '+1-555-0104', 'sarah.johnson@inventory.com', 30000),
('Overflow Storage - East', 'Boston, MA 02101', 'Michael Brown', '+1-555-0105', 'michael.brown@inventory.com', 20000);

-- ============================================
-- CATEGORIES
-- ============================================

INSERT INTO categories (category_name, description, parent_category_id) VALUES
('Electronics', 'Electronic devices and components', NULL),
('Computers', 'Desktop and laptop computers', 1),
('Accessories', 'Computer accessories and peripherals', 1),
('Home Appliances', 'Home and kitchen appliances', NULL),
('Small Appliances', 'Small kitchen appliances', 4),
('Large Appliances', 'Large home appliances', 4),
('Office Supplies', 'Office and stationery supplies', NULL),
('Furniture', 'Office and home furniture', NULL),
('Industrial Equipment', 'Heavy machinery and industrial tools', NULL),
('Safety Equipment', 'Personal protective equipment', NULL);

-- ============================================
-- PRODUCTS
-- ============================================

INSERT INTO products (product_code, product_name, description, category_id, unit_of_measure, unit_price, reorder_level, minimum_stock, maximum_stock) VALUES
-- Electronics
('ELEC-LP-001', 'Dell Latitude 5520 Laptop', '15.6" Business Laptop, Intel i7, 16GB RAM', 2, 'unit', 1299.99, 20, 10, 100),
('ELEC-LP-002', 'HP ProBook 450 G8', '15.6" Professional Laptop, Intel i5, 8GB RAM', 2, 'unit', 899.99, 25, 15, 120),
('ELEC-MN-001', 'Dell UltraSharp U2720Q Monitor', '27" 4K USB-C Monitor', 3, 'unit', 599.99, 15, 8, 80),
('ELEC-KB-001', 'Logitech MX Keys Keyboard', 'Wireless illuminated keyboard', 3, 'unit', 99.99, 50, 20, 200),
('ELEC-MS-001', 'Logitech MX Master 3 Mouse', 'Advanced wireless mouse', 3, 'unit', 99.99, 50, 20, 200),
('ELEC-HD-001', 'Seagate 2TB External HDD', 'Portable external hard drive', 3, 'unit', 79.99, 40, 20, 150),

-- Home Appliances
('APPL-CF-001', 'Keurig K-Elite Coffee Maker', 'Single serve coffee maker', 5, 'unit', 149.99, 30, 15, 100),
('APPL-BL-001', 'Ninja Professional Blender', '1000W professional blender', 5, 'unit', 89.99, 25, 12, 80),
('APPL-MW-001', 'Panasonic Microwave Oven', '1.2 Cu.Ft countertop microwave', 5, 'unit', 179.99, 20, 10, 60),
('APPL-RF-001', 'Samsung French Door Refrigerator', '28 cu ft stainless steel', 6, 'unit', 2199.99, 5, 2, 20),
('APPL-WM-001', 'LG Front Load Washing Machine', '5.0 cu ft capacity', 6, 'unit', 1099.99, 8, 3, 30),

-- Office Supplies
('OFFC-PEN-001', 'BIC Cristal Ballpoint Pens', 'Medium point, black ink (box of 50)', 7, 'box', 12.99, 100, 50, 500),
('OFFC-NTB-001', 'Moleskine Classic Notebook', 'Hard cover, ruled, large', 7, 'unit', 19.99, 80, 40, 300),
('OFFC-PPR-001', 'HP Copy Paper', 'Letter size, 500 sheets', 7, 'ream', 8.99, 200, 100, 1000),
('OFFC-STL-001', 'Swingline Stapler', 'Standard desktop stapler', 7, 'unit', 14.99, 60, 30, 200),

-- Furniture
('FURN-DSK-001', 'Standing Desk Electric', 'Adjustable height desk, 60"x30"', 8, 'unit', 499.99, 10, 5, 40),
('FURN-CHR-001', 'Herman Miller Aeron Chair', 'Ergonomic office chair, size B', 8, 'unit', 1395.00, 8, 4, 30),
('FURN-CAB-001', 'Filing Cabinet 4-Drawer', 'Vertical file cabinet, letter size', 8, 'unit', 249.99, 15, 8, 50),

-- Industrial Equipment
('INDL-DRL-001', 'DeWalt Cordless Drill', '20V MAX drill/driver kit', 9, 'unit', 149.99, 20, 10, 80),
('INDL-SAW-001', 'Makita Circular Saw', '7-1/4" cordless circular saw', 9, 'unit', 199.99, 15, 8, 60),

-- Safety Equipment
('SAFE-HLM-001', 'Hard Hat Safety Helmet', 'ANSI Z89.1 certified', 10, 'unit', 19.99, 100, 50, 400),
('SAFE-GLV-001', 'Safety Gloves', 'Cut-resistant, size L (pair)', 10, 'pair', 12.99, 150, 75, 600),
('SAFE-GSL-001', 'Safety Goggles', 'Anti-fog, UV protection', 10, 'unit', 9.99, 120, 60, 500);

-- ============================================
-- INITIAL INVENTORY
-- ============================================

-- Main Warehouse - North
INSERT INTO inventory (warehouse_id, product_id, quantity_on_hand, quantity_reserved) VALUES
(1, 1, 45, 5),   -- Laptops
(1, 2, 60, 10),
(1, 3, 35, 3),   -- Monitors
(1, 4, 120, 15),  -- Keyboards
(1, 5, 115, 10),  -- Mice
(1, 6, 80, 8),   -- HDDs
(1, 7, 55, 5),   -- Coffee Makers
(1, 8, 42, 4),   -- Blenders
(1, 15, 25, 2),  -- Standing Desks
(1, 16, 18, 3),  -- Office Chairs
(1, 19, 45, 5),  -- Safety Helmets
(1, 20, 280, 30); -- Safety Gloves

-- Distribution Center - South
INSERT INTO inventory (warehouse_id, product_id, quantity_on_hand, quantity_reserved) VALUES
(2, 1, 32, 2),
(2, 2, 48, 8),
(2, 4, 95, 10),
(2, 5, 88, 7),
(2, 10, 8, 1),   -- Refrigerators
(2, 11, 15, 2),  -- Washing Machines
(2, 12, 420, 40), -- Pens
(2, 13, 165, 15), -- Notebooks
(2, 14, 850, 50), -- Copy Paper
(2, 21, 380, 25); -- Safety Goggles

-- Regional Hub - West
INSERT INTO inventory (warehouse_id, product_id, quantity_on_hand, quantity_reserved) VALUES
(3, 1, 28, 3),
(3, 2, 55, 5),
(3, 3, 42, 4),
(3, 6, 95, 10),
(3, 7, 48, 5),
(3, 9, 32, 3),   -- Microwaves
(3, 15, 18, 1),
(3, 17, 28, 3),  -- Filing Cabinets
(3, 18, 35, 5),  -- Drills
(3, 19, 225, 15);

-- Distribution Center - Central
INSERT INTO inventory (warehouse_id, product_id, quantity_on_hand, quantity_reserved) VALUES
(4, 2, 38, 4),
(4, 4, 105, 12),
(4, 5, 98, 8),
(4, 8, 35, 3),
(4, 12, 580, 30),
(4, 13, 245, 20),
(4, 14, 1250, 100),
(4, 20, 520, 40);

-- Overflow Storage - East
INSERT INTO inventory (warehouse_id, product_id, quantity_on_hand, quantity_reserved) VALUES
(5, 6, 120, 10),
(5, 12, 950, 50),
(5, 13, 420, 30),
(5, 14, 1850, 150),
(5, 19, 380, 20),
(5, 20, 640, 35),
(5, 21, 510, 25);

-- ============================================
-- SAMPLE STOCK MOVEMENTS
-- ============================================

-- Purchases (Inbound)
INSERT INTO stock_movements (movement_type_id, product_id, to_warehouse_id, quantity, unit_cost, reference_number, created_by, movement_date) VALUES
(1, 1, 1, 50, 1100.00, 'PO-2025-001', 'system', '2025-10-01 09:30:00'),
(1, 2, 1, 70, 750.00, 'PO-2025-002', 'system', '2025-10-01 10:15:00'),
(1, 4, 2, 100, 75.00, 'PO-2025-003', 'system', '2025-10-02 11:00:00'),
(1, 12, 5, 1000, 9.50, 'PO-2025-004', 'system', '2025-10-03 14:20:00');

-- Sales (Outbound)
INSERT INTO stock_movements (movement_type_id, product_id, from_warehouse_id, quantity, unit_cost, reference_number, created_by, movement_date) VALUES
(2, 1, 1, 5, 1299.99, 'SO-2025-001', 'system', '2025-10-15 13:45:00'),
(2, 4, 2, 5, 99.99, 'SO-2025-002', 'system', '2025-10-16 10:30:00'),
(2, 12, 2, 20, 12.99, 'SO-2025-003', 'system', '2025-10-17 15:00:00');

-- Transfers
INSERT INTO stock_movements (movement_type_id, product_id, from_warehouse_id, to_warehouse_id, quantity, unit_cost, reference_number, created_by, movement_date) VALUES
(5, 6, 1, 3, 15, 79.99, 'TRF-2025-001', 'system', '2025-10-20 09:00:00'),
(5, 13, 5, 2, 20, 19.99, 'TRF-2025-002', 'system', '2025-10-21 11:30:00');

-- ============================================
-- SAMPLE USERS
-- ============================================

INSERT INTO users (username, full_name, email, password_hash, role) VALUES
('admin', 'System Administrator', 'admin@inventory.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ADMIN'),
('jsmith', 'John Smith', 'john.smith@inventory.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'MANAGER'),
('mgarcia', 'Maria Garcia', 'maria.garcia@inventory.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'MANAGER'),
('operator1', 'Warehouse Operator', 'operator@inventory.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'OPERATOR'),
('viewer1', 'Report Viewer', 'viewer@inventory.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'VIEWER');

-- Enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Show inventory status
SELECT * FROM v_inventory_status LIMIT 10;

-- Show products to reorder
SELECT * FROM v_products_to_reorder;

-- Show recent movements
SELECT * FROM v_stock_movement_summary LIMIT 10;

-- Summary statistics
SELECT 
    'Total Warehouses' AS metric, COUNT(*) AS value FROM warehouses
UNION ALL
SELECT 'Total Products', COUNT(*) FROM products
UNION ALL
SELECT 'Total Categories', COUNT(*) FROM categories
UNION ALL
SELECT 'Total Inventory Records', COUNT(*) FROM inventory
UNION ALL
SELECT 'Total Stock Movements', COUNT(*) FROM stock_movements
UNION ALL
SELECT 'Total Audit Records', COUNT(*) FROM inventory_audit;