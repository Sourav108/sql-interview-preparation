-- ============================================================
-- E-Commerce Dataset: Validation Reference Queries
-- Validates correct schema behavior and referential integrity
-- Run after schema.sql + seed.sql
-- PostgreSQL 18.6 | sql-interview-preparation
-- ============================================================

-- ── 1. Row count verification ────────────────────────────────
SELECT 'customers'  AS tbl, COUNT(*) FROM customers
UNION ALL
SELECT 'products',   COUNT(*) FROM products
UNION ALL
SELECT 'inventory',  COUNT(*) FROM inventory
UNION ALL
SELECT 'orders',     COUNT(*) FROM orders
UNION ALL
SELECT 'order_items',COUNT(*) FROM order_items
UNION ALL
SELECT 'payments',   COUNT(*) FROM payments;
-- Expected: 12, 8, 8, 11, 18, 10

-- ── 2. Customers with no orders (Anti-join) ──────────────────
SELECT c.first_name, c.last_name, c.email
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.id
);
-- Expected: Henry, James, Karen, Leo (4 rows)

-- ── 3. Revenue per customer (aggregation) ───────────────────
SELECT
    c.first_name || ' ' || c.last_name AS customer,
    COUNT(o.id)                         AS order_count,
    SUM(o.total)                        AS gross_revenue
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE o.status <> 'CANCELLED'
GROUP BY c.id, c.first_name, c.last_name
ORDER BY gross_revenue DESC;

-- ── 4. Products sold with revenue (join + aggregation) ───────
SELECT
    p.name,
    SUM(oi.quantity)                  AS total_units,
    SUM(oi.quantity * oi.unit_price)  AS revenue
FROM order_items oi
JOIN products p ON p.id = oi.product_id
JOIN orders   o ON o.id = oi.order_id
WHERE o.status IN ('DELIVERED', 'SHIPPED', 'CONFIRMED')
GROUP BY p.id, p.name
ORDER BY revenue DESC;

-- ── 5. Orders with pending payment ──────────────────────────
SELECT o.id, o.total, o.status, o.placed_at
FROM orders o
LEFT JOIN payments p ON p.order_id = o.id AND p.status = 'COMPLETED'
WHERE p.id IS NULL
ORDER BY o.placed_at;
-- Expected: Order 6 (Carol/PENDING), Order 10 (Grace/PENDING), Order 11 (Irene no payment row)

-- ── 6. Validate: no order_items point to non-existent orders ─
SELECT COUNT(*) AS orphan_items
FROM order_items oi
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.id = oi.order_id);
-- Expected: 0
