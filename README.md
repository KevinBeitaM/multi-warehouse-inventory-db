# 🏭 Multi-Warehouse Inventory Management System

A comprehensive database solution for managing inventory across multiple warehouses with automated audit trails, stock movement tracking, and real-time alerts.

## 📋 Table of Contents


- [Database Schema](#database-schema)
- [Installation](#installation)
- [Usage](#usage)
- [Stored Procedures](#stored-procedures)
- [Triggers & Automation](#triggers--automation)
- [Performance Optimization](#performance-optimization)
- [Sample Queries](#sample-queries)




## ✨ Features

### Core Functionality
- ✅ **Multi-warehouse management** - Track inventory across unlimited locations
- ✅ **Product categorization** - Hierarchical category structure
- ✅ **Stock movement tracking** - Purchase, sales, transfers, adjustments
- ✅ **Reserved inventory** - Track committed vs available stock
- ✅ **Reorder automation** - Automated alerts for low stock

### Data Integrity
- 🔒 **Audit trail** - Complete history of all inventory changes
- 🔒 **Triggers** - Automatic logging of all modifications
- 🔒 **Constraints** - Data validation at database level
- 🔒 **Referential integrity** - Foreign key relationships
- 🔒 **Generated columns** - Calculated fields for data consistency

### Performance
- ⚡ **Optimized indexes** - Composite indexes for common queries
- ⚡ **Materialized views** - Pre-computed aggregations
- ⚡ **Partitioning ready** - Scalable architecture
- ⚡ **Query optimization** - Efficient stored procedures

### Reporting & Analytics
- 📊 **Inventory snapshots** - Daily historical records
- 📊 **Stock alerts** - Automated low stock notifications
- 📊 **Movement reports** - Comprehensive audit reports
- 📊 **Pre-built views** - Ready-to-use reporting queries

## 🗄️ Database Schema

### Core Tables

| Table | Description | Key Features |
|-------|-------------|--------------|
| `warehouses` | Physical warehouse locations | Manager info, capacity tracking |
| `categories` | Product categorization | Hierarchical structure |
| `products` | Product master data | SKU, pricing, stock thresholds |
| `inventory` | Current stock levels | Computed available quantity |
| `stock_movements` | All stock transactions | Complete movement history |
| `movement_types` | Transaction type definitions | IN/OUT/TRANSFER |

### Audit & Control Tables

| Table | Description |
|-------|-------------|
| `inventory_audit` | Complete inventory change log |
| `movement_audit` | Stock movement audit trail |
| `stock_alerts` | Automated stock alerts |
| `inventory_snapshots` | Daily inventory history |

### User Management

| Table | Description |
|-------|-------------|
| `users` | System users with role-based access |

## 🚀 Installation

### Prerequisites
- MySQL 8.0 or higher
- Database client (MySQL Workbench, DBeaver, etc.)
- Minimum 100MB storage space

### Step 1: Create Database

```bash
mysql -u root -p < database/schema.sql
```

### Step 2: Create Procedures & Triggers

```bash
mysql -u root -p < database/procedures_triggers.sql
```

### Step 3: Load Sample Data (Optional)

```bash
mysql -u root -p < database/data.sql
```

### Step 4: Verify Installation

```sql
USE inventory_system;
SHOW TABLES;
CALL sp_inventory_report(1);
```

## 📖 Usage

### Adding Stock (Purchase)

```sql
CALL sp_add_stock(
    1,                          -- warehouse_id
    1,                          -- product_id
    100,                        -- quantity
    1100.00,                    -- unit_cost
    'PO-2025-1234',            -- reference_number
    'jsmith',                   -- created_by
    'New stock from supplier'   -- notes
);
```

### Removing Stock (Sale)

```sql
CALL sp_remove_stock(
    1,                          -- warehouse_id
    1,                          -- product_id
    10,                         -- quantity
    'SO-2025-5678',            -- reference_number
    'mgarcia',                  -- created_by
    'Customer order #5678'      -- notes
);
```

### Transferring Between Warehouses

```sql
CALL sp_transfer_stock(
    1,                          -- from_warehouse_id
    2,                          -- to_warehouse_id
    1,                          -- product_id
    25,                         -- quantity
    'TRF-2025-9012',           -- reference_number
    'admin',                    -- created_by
    'Rebalancing inventory'     -- notes
);
```

### Generating Reports

```sql
-- Inventory status by warehouse
CALL sp_inventory_report(1);

-- Product movement history (last 30 days)
CALL sp_movement_history(1, 30);

-- Products needing reorder
SELECT * FROM v_products_to_reorder;

-- Current stock alerts
SELECT * FROM stock_alerts WHERE alert_status = 'OPEN';
```

## 🔧 Stored Procedures

| Procedure | Description | Parameters |
|-----------|-------------|------------|
| `sp_add_stock` | Add inventory (purchase/receipt) | warehouse_id, product_id, quantity, unit_cost, reference, user, notes |
| `sp_remove_stock` | Remove inventory (sale/consumption) | warehouse_id, product_id, quantity, reference, user, notes |
| `sp_transfer_stock` | Transfer between warehouses | from_warehouse, to_warehouse, product_id, quantity, reference, user, notes |
| `sp_inventory_report` | Get inventory status by warehouse | warehouse_id |
| `sp_movement_history` | Get product movement history | product_id, days |

## 🤖 Triggers & Automation

### Audit Triggers
- `trg_inventory_after_insert` - Log new inventory records
- `trg_inventory_after_update` - Track quantity changes
- `trg_inventory_after_delete` - Record deletions
- `trg_movement_after_insert` - Audit stock movements

### Alert Triggers
- `trg_check_stock_alerts` - Create alerts for low/out of stock
- Auto-resolve alerts when stock is replenished

### Scheduled Events
- `evt_daily_inventory_snapshot` - Daily inventory snapshot at 2:00 AM

## ⚡ Performance Optimization

### Indexes Implemented

```sql
-- Composite indexes for common queries
idx_inventory_warehouse_product_qty
idx_movements_date_type
idx_movements_product_date

-- Full-text search
ft_product_search (product_name, description)
```

### Query Optimization Tips

1. **Use views for complex queries**
   ```sql
   SELECT * FROM v_inventory_status WHERE stock_status = 'LOW';
   ```

2. **Leverage indexes**
   ```sql
   -- Use indexed columns in WHERE clauses
   SELECT * FROM inventory WHERE warehouse_id = 1 AND product_id = 5;
   ```

3. **Batch operations**
   ```sql
   -- Use transactions for multiple operations
   START TRANSACTION;
   -- Multiple operations
   COMMIT;
   ```

## 📝 Sample Queries

### Total Inventory Value by Warehouse

```sql
SELECT 
    w.warehouse_name,
    COUNT(DISTINCT i.product_id) AS total_products,
    SUM(i.quantity_available) AS total_units,
    SUM(i.quantity_available * p.unit_price) AS total_value
FROM inventory i
JOIN warehouses w ON i.warehouse_id = w.warehouse_id
JOIN products p ON i.product_id = p.product_id
GROUP BY w.warehouse_id, w.warehouse_name
ORDER BY total_value DESC;
```

### Top Moving Products (Last 30 Days)

```sql
SELECT 
    p.product_code,
    p.product_name,
    COUNT(sm.movement_id) AS transaction_count,
    SUM(sm.quantity) AS total_quantity_moved,
    SUM(sm.total_cost) AS total_value
FROM stock_movements sm
JOIN products p ON sm.product_id = p.product_id
WHERE sm.movement_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY p.product_id
ORDER BY total_quantity_moved DESC
LIMIT 10;
```

### Warehouse Capacity Utilization

```sql
SELECT 
    w.warehouse_name,
    w.capacity AS max_capacity,
    SUM(i.quantity_on_hand) AS current_stock,
    ROUND((SUM(i.quantity_on_hand) / w.capacity) * 100, 2) AS utilization_percent
FROM warehouses w
LEFT JOIN inventory i ON w.warehouse_id = i.warehouse_id
GROUP BY w.warehouse_id
ORDER BY utilization_percent DESC;
```

### Audit Trail - Recent Changes

```sql
SELECT 
    ia.changed_at,
    w.warehouse_name,
    p.product_name,
    ia.old_quantity,
    ia.new_quantity,
    ia.quantity_change,
    ia.changed_by
FROM inventory_audit ia
JOIN warehouses w ON ia.warehouse_id = w.warehouse_id
JOIN products p ON ia.product_id = p.product_id
ORDER BY ia.changed_at DESC
LIMIT 50;
```



