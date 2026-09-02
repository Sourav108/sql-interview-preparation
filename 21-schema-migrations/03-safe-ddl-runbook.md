# 03. Safe DDL Runbook for High-Traffic Tables

## 1. Safely Adding a `NOT NULL` Column

### ❌ Dangerous Naive Approach:
```sql
-- Scans and rewrites entire 100M-row table while holding ACCESS EXCLUSIVE lock!
ALTER TABLE orders ADD COLUMN is_fulfilled BOOLEAN NOT NULL DEFAULT false;
```

### ✅ Safe 3-Step Production Pattern (PostgreSQL):
```sql
-- Step 1: Add column as nullable (in PG 11+, DEFAULT with constant is metadata-only - instant!)
ALTER TABLE orders ADD COLUMN is_fulfilled BOOLEAN DEFAULT false;

-- Step 2: Add CHECK constraint WITHOUT validation (instant metadata lock)
ALTER TABLE orders ADD CONSTRAINT chk_orders_fulfilled_not_null
    CHECK (is_fulfilled IS NOT NULL) NOT VALID;

-- Step 3: Validate constraint concurrently (only takes SHARE UPDATE EXCLUSIVE lock - readers and writers proceed!)
ALTER TABLE orders VALIDATE CONSTRAINT chk_orders_fulfilled_not_null;
```

---

## 2. Safely Adding a Foreign Key Constraint

### ✅ Safe Pattern:
```sql
-- 1. Add constraint marked NOT VALID (Instant lock acquisition)
ALTER TABLE order_items ADD CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id) REFERENCES products (id) NOT VALID;

-- 2. Validate in background without locking writers
ALTER TABLE order_items VALIDATE CONSTRAINT fk_order_items_product;
```
