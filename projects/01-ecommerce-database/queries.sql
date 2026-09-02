-- 1. Total revenue per customer
SELECT
    c.full_name,
    COUNT(DISTINCT o.id) AS total_orders,
    COALESCE(SUM(o.total), 0) AS total_spent
FROM proj_customers c
LEFT JOIN proj_orders o ON o.customer_id = c.id AND o.status = 'DELIVERED'
GROUP BY c.id, c.full_name;

-- 2. Low stock alert
SELECT p.title, p.sku, i.stock_qty
FROM proj_products p
JOIN proj_inventory i ON i.product_id = p.id
WHERE i.stock_qty < 20;
