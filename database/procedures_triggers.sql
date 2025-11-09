-- ============================================
-- STORED PROCEDURES & TRIGGERS
-- Author: Kevin Beita Marín
-- Description: Automation for stock movements and audit triggers
-- ============================================

USE inventory_system;

DELIMITER $$

-- ============================================
-- STORED PROCEDURES
-- ============================================

-- Procedure: Add Stock (Inbound Movement)
CREATE PROCEDURE sp_add_stock(
    IN p_warehouse_id INT,
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_unit_cost DECIMAL(10,2),
    IN p_reference VARCHAR(100),
    IN p_created_by VARCHAR(100),
    IN p_notes TEXT
)
BEGIN
    DECLARE v_movement_type_id INT;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Get movement type for 'PURCHASE' or 'INBOUND'
    SELECT movement_type_id INTO v_movement_type_id 
    FROM movement_types 
    WHERE type_code = 'PURCHASE' LIMIT 1;
    
    -- Insert stock movement
    INSERT INTO stock_movements (
        movement_type_id, product_id, to_warehouse_id, 
        quantity, unit_cost, reference_number, notes, created_by
    ) VALUES (
        v_movement_type_id, p_product_id, p_warehouse_id, 
        p_quantity, p_unit_cost, p_reference, p_notes, p_created_by
    );
    
    -- Update inventory (INSERT or UPDATE)
    INSERT INTO inventory (warehouse_id, product_id, quantity_on_hand)
    VALUES (p_warehouse_id, p_product_id, p_quantity)
    ON DUPLICATE KEY UPDATE 
        quantity_on_hand = quantity_on_hand + p_quantity;
    
    COMMIT;
    
    SELECT 'Stock added successfully' AS message, LAST_INSERT_ID() AS movement_id;
END$$

-- Procedure: Remove Stock (Outbound Movement)
CREATE PROCEDURE sp_remove_stock(
    IN p_warehouse_id INT,
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_reference VARCHAR(100),
    IN p_created_by VARCHAR(100),
    IN p_notes TEXT
)
BEGIN
    DECLARE v_movement_type_id INT;
    DECLARE v_available_qty INT;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Check available quantity
    SELECT quantity_available INTO v_available_qty
    FROM inventory
    WHERE warehouse_id = p_warehouse_id AND product_id = p_product_id;
    
    IF v_available_qty IS NULL OR v_available_qty < p_quantity THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Insufficient stock available';
    END IF;
    
    -- Get movement type for 'SALE' or 'OUTBOUND'
    SELECT movement_type_id INTO v_movement_type_id 
    FROM movement_types 
    WHERE type_code = 'SALE' LIMIT 1;
    
    -- Insert stock movement
    INSERT INTO stock_movements (
        movement_type_id, product_id, from_warehouse_id, 
        quantity, reference_number, notes, created_by
    ) VALUES (
        v_movement_type_id, p_product_id, p_warehouse_id, 
        p_quantity, p_reference, p_notes, p_created_by
    );
    
    -- Update inventory
    UPDATE inventory 
    SET quantity_on_hand = quantity_on_hand - p_quantity
    WHERE warehouse_id = p_warehouse_id AND product_id = p_product_id;
    
    COMMIT;
    
    SELECT 'Stock removed successfully' AS message, LAST_INSERT_ID() AS movement_id;
END$$

-- Procedure: Transfer Stock Between Warehouses
CREATE PROCEDURE sp_transfer_stock(
    IN p_from_warehouse_id INT,
    IN p_to_warehouse_id INT,
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_reference VARCHAR(100),
    IN p_created_by VARCHAR(100),
    IN p_notes TEXT
)
BEGIN
    DECLARE v_movement_type_id INT;
    DECLARE v_available_qty INT;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Validate warehouses are different
    IF p_from_warehouse_id = p_to_warehouse_id THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Source and destination warehouses must be different';
    END IF;
    
    -- Check available quantity in source warehouse
    SELECT quantity_available INTO v_available_qty
    FROM inventory
    WHERE warehouse_id = p_from_warehouse_id AND product_id = p_product_id;
    
    IF v_available_qty IS NULL OR v_available_qty < p_quantity THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Insufficient stock in source warehouse';
    END IF;
    
    -- Get movement type for 'TRANSFER'
    SELECT movement_type_id INTO v_movement_type_id 
    FROM movement_types 
    WHERE type_code = 'TRANSFER' LIMIT 1;
    
    -- Insert stock movement
    INSERT INTO stock_movements (
        movement_type_id, product_id, from_warehouse_id, to_warehouse_id,
        quantity, reference_number, notes, created_by
    ) VALUES (
        v_movement_type_id, p_product_id, p_from_warehouse_id, p_to_warehouse_id,
        p_quantity, p_reference, p_notes, p_created_by
    );
    
    -- Update source warehouse inventory
    UPDATE inventory 
    SET quantity_on_hand = quantity_on_hand - p_quantity
    WHERE warehouse_id = p_from_warehouse_id AND product_id = p_product_id;
    
    -- Update destination warehouse inventory
    INSERT INTO inventory (warehouse_id, product_id, quantity_on_hand)
    VALUES (p_to_warehouse_id, p_product_id, p_quantity)
    ON DUPLICATE KEY UPDATE 
        quantity_on_hand = quantity_on_hand + p_quantity;
    
    COMMIT;
    
    SELECT 'Stock transferred successfully' AS message, LAST_INSERT_ID() AS movement_id;
END$$

-- Procedure: Get Inventory Report by Warehouse
CREATE PROCEDURE sp_inventory_report(
    IN p_warehouse_id INT
)
BEGIN
    SELECT 
        p.product_code,
        p.product_name,
        c.category_name,
        i.quantity_on_hand,
        i.quantity_reserved,
        i.quantity_available,
        p.reorder_level,
        p.unit_price,
        (i.quantity_available * p.unit_price) AS total_value,
        CASE 
            WHEN i.quantity_available <= 0 THEN 'OUT_OF_STOCK'
            WHEN i.quantity_available <= p.minimum_stock THEN 'CRITICAL'
            WHEN i.quantity_available <= p.reorder_level THEN 'LOW'
            ELSE 'NORMAL'
        END AS stock_status
    FROM inventory i
    INNER JOIN products p ON i.product_id = p.product_id
    INNER JOIN categories c ON p.category_id = c.category_id
    WHERE i.warehouse_id = p_warehouse_id
    ORDER BY stock_status DESC, p.product_name;
END$$

-- Procedure: Get Stock Movement History
CREATE PROCEDURE sp_movement_history(
    IN p_product_id INT,
    IN p_days INT
)
BEGIN
    SELECT 
        sm.movement_id,
        mt.type_name,
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
    LEFT JOIN warehouses wf ON sm.from_warehouse_id = wf.warehouse_id
    LEFT JOIN warehouses wt ON sm.to_warehouse_id = wt.warehouse_id
    WHERE sm.product_id = p_product_id
      AND sm.movement_date >= DATE_SUB(NOW(), INTERVAL p_days DAY)
    ORDER BY sm.movement_date DESC;
END$$

-- ============================================
-- TRIGGERS FOR AUDIT TRAIL
-- ============================================

-- Trigger: After INSERT on inventory
CREATE TRIGGER trg_inventory_after_insert
AFTER INSERT ON inventory
FOR EACH ROW
BEGIN
    INSERT INTO inventory_audit (
        inventory_id, warehouse_id, product_id,
        old_quantity, new_quantity, quantity_change,
        old_reserved, new_reserved,
        change_type, changed_by
    ) VALUES (
        NEW.inventory_id, NEW.warehouse_id, NEW.product_id,
        0, NEW.quantity_on_hand, NEW.quantity_on_hand,
        0, NEW.quantity_reserved,
        'INSERT', COALESCE(USER(), 'SYSTEM')
    );
END$$

-- Trigger: After UPDATE on inventory
CREATE TRIGGER trg_inventory_after_update
AFTER UPDATE ON inventory
FOR EACH ROW
BEGIN
    INSERT INTO inventory_audit (
        inventory_id, warehouse_id, product_id,
        old_quantity, new_quantity, quantity_change,
        old_reserved, new_reserved,
        change_type, changed_by
    ) VALUES (
        NEW.inventory_id, NEW.warehouse_id, NEW.product_id,
        OLD.quantity_on_hand, NEW.quantity_on_hand, 
        NEW.quantity_on_hand - OLD.quantity_on_hand,
        OLD.quantity_reserved, NEW.quantity_reserved,
        'UPDATE', COALESCE(USER(), 'SYSTEM')
    );
END$$

-- Trigger: After DELETE on inventory
CREATE TRIGGER trg_inventory_after_delete
AFTER DELETE ON inventory
FOR EACH ROW
BEGIN
    INSERT INTO inventory_audit (
        inventory_id, warehouse_id, product_id,
        old_quantity, new_quantity, quantity_change,
        old_reserved, new_reserved,
        change_type, changed_by
    ) VALUES (
        OLD.inventory_id, OLD.warehouse_id, OLD.product_id,
        OLD.quantity_on_hand, 0, -OLD.quantity_on_hand,
        OLD.quantity_reserved, 0,
        'DELETE', COALESCE(USER(), 'SYSTEM')
    );
END$$

-- ============================================
-- TRIGGERS FOR STOCK ALERTS
-- ============================================

-- Trigger: Check for low stock after inventory update
CREATE TRIGGER trg_check_stock_alerts
AFTER UPDATE ON inventory
FOR EACH ROW
BEGIN
    DECLARE v_reorder_level INT;
    DECLARE v_minimum_stock INT;
    
    -- Get product thresholds
    SELECT reorder_level, minimum_stock INTO v_reorder_level, v_minimum_stock
    FROM products
    WHERE product_id = NEW.product_id;
    
    -- Create alert for OUT_OF_STOCK
    IF NEW.quantity_available <= 0 AND OLD.quantity_available > 0 THEN
        INSERT INTO stock_alerts (
            warehouse_id, product_id, alert_type, 
            current_quantity, threshold_quantity
        ) VALUES (
            NEW.warehouse_id, NEW.product_id, 'OUT_OF_STOCK',
            NEW.quantity_available, v_minimum_stock
        );
    
    -- Create alert for LOW_STOCK
    ELSEIF NEW.quantity_available <= v_reorder_level AND OLD.quantity_available > v_reorder_level THEN
        INSERT INTO stock_alerts (
            warehouse_id, product_id, alert_type, 
            current_quantity, threshold_quantity
        ) VALUES (
            NEW.warehouse_id, NEW.product_id, 'LOW_STOCK',
            NEW.quantity_available, v_reorder_level
        );
    
    -- Auto-resolve alerts if stock is replenished
    ELSEIF NEW.quantity_available > v_reorder_level AND OLD.quantity_available <= v_reorder_level THEN
        UPDATE stock_alerts
        SET alert_status = 'RESOLVED',
            resolved_at = CURRENT_TIMESTAMP,
            notes = 'Auto-resolved: Stock replenished'
        WHERE warehouse_id = NEW.warehouse_id
          AND product_id = NEW.product_id
          AND alert_status = 'OPEN';
    END IF;
END$$

-- ============================================
-- TRIGGERS FOR MOVEMENT AUDIT
-- ============================================

-- Trigger: After INSERT on stock_movements
CREATE TRIGGER trg_movement_after_insert
AFTER INSERT ON stock_movements
FOR EACH ROW
BEGIN
    INSERT INTO movement_audit (
        movement_id, action_type, new_data, changed_by
    ) VALUES (
        NEW.movement_id, 'CREATED',
        JSON_OBJECT(
            'movement_type_id', NEW.movement_type_id,
            'product_id', NEW.product_id,
            'from_warehouse_id', NEW.from_warehouse_id,
            'to_warehouse_id', NEW.to_warehouse_id,
            'quantity', NEW.quantity,
            'unit_cost', NEW.unit_cost,
            'reference_number', NEW.reference_number
        ),
        COALESCE(NEW.created_by, USER())
    );
END$$

-- ============================================
-- EVENT SCHEDULER FOR DAILY SNAPSHOTS
-- ============================================

-- Enable event scheduler
SET GLOBAL event_scheduler = ON$$

-- Event: Daily Inventory Snapshot
CREATE EVENT IF NOT EXISTS evt_daily_inventory_snapshot
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 2 HOUR
DO
BEGIN
    INSERT INTO inventory_snapshots (
        warehouse_id, product_id, quantity_on_hand, 
        quantity_reserved, quantity_available, snapshot_date
    )
    SELECT 
        warehouse_id, product_id, quantity_on_hand,
        quantity_reserved, quantity_available, CURDATE()
    FROM inventory
    ON DUPLICATE KEY UPDATE
        quantity_on_hand = VALUES(quantity_on_hand),
        quantity_reserved = VALUES(quantity_reserved),
        quantity_available = VALUES(quantity_available);
END$$

DELIMITER ;

-- ============================================
-- GRANT PERMISSIONS (Optional)
-- ============================================

-- Create roles for different user types
-- GRANT SELECT, INSERT, UPDATE ON inventory_system.* TO 'inventory_operator'@'%';
-- GRANT ALL PRIVILEGES ON inventory_system.* TO 'inventory_admin'@'%';
-- GRANT SELECT ON inventory_system.* TO 'inventory_viewer'@'%';