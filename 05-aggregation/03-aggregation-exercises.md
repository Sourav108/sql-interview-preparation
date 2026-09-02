# 03. Aggregation Exercises — Business Reporting Problems

All queries use `datasets/ecommerce/`. Expected outputs are validated against the seed data.

---

## Problem 1: Revenue Summary by Order Status

**Question**: Show total orders, total revenue, and average order value for each order status. Sort by revenue descending.

**Solution**:
```sql
SELECT
    status,
    COUNT(*)                        AS order_count,
    SUM(total)                      AS total_revenue,
    ROUND(AVG(total)::NUMERIC, 2)   AS avg_order_value,
    MIN(total)                      AS min_order,
    MAX(total)                      AS max_order
FROM orders
GROUP BY status
ORDER BY total_revenue DESC NULLS LAST;
```

---

## Problem 2: Top 3 Customers by Lifetime Value

**Question**: Find the top 3 customers by total amount spent on DELIVERED or SHIPPED orders. Show their email, order count, and total spent.

**Solution**:
```sql
SELECT
    c.email,
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(DISTINCT o.id)               AS order_count,
    SUM(o.total)                       AS lifetime_value
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE o.status IN ('DELIVERED', 'SHIPPED')
GROUP BY c.id, c.email, c.first_name, c.last_name
ORDER BY lifetime_value DESC
LIMIT 3;
```

**Expected**:
| email | customer_name | order_count | lifetime_value |
| :--- | :--- | :--- | :--- |
| eva.steele@example.com | Eva Steele | 1 | 16050.00 |
| frank.muller@example.com | Frank Muller | 1 | 14250.00 |
| david.nakamura@example.com | David Nakamura | 1 | 12700.00 |

---

## Problem 3: Products Sold — Units and Revenue

**Question**: For each product, show total units sold and revenue generated, only from non-cancelled orders. Include products with zero sales.

**Solution**:
```sql
SELECT
    p.sku,
    p.name,
    COALESCE(SUM(oi.quantity), 0)                  AS units_sold,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0)  AS revenue
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.id
LEFT JOIN orders o ON o.id = oi.order_id AND o.status <> 'CANCELLED'
GROUP BY p.id, p.sku, p.name
ORDER BY revenue DESC;
```

**Key**: `LEFT JOIN` from products ensures discontinued or never-sold products (SKU-CAB-01) appear with 0 values.

---

## Problem 4: Monthly Order Volume and Revenue Trend

**Question**: Show month-by-month total orders and revenue for all non-cancelled orders.

**Solution**:
```sql
SELECT
    DATE_TRUNC('month', placed_at)::DATE    AS month,
    COUNT(*)                                 AS orders,
    SUM(total)                               AS revenue,
    ROUND(AVG(total)::NUMERIC, 2)            AS avg_order_value
FROM orders
WHERE status <> 'CANCELLED'
GROUP BY DATE_TRUNC('month', placed_at)
ORDER BY month;
```

---

## Problem 5: Customers Who Ordered in Multiple Months

**Question**: Find customers who placed orders in at least 2 distinct calendar months.

**Solution**:
```sql
SELECT
    c.email,
    COUNT(DISTINCT DATE_TRUNC('month', o.placed_at)) AS active_months,
    MIN(o.placed_at)::DATE                           AS first_order,
    MAX(o.placed_at)::DATE                           AS latest_order
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.email
HAVING COUNT(DISTINCT DATE_TRUNC('month', o.placed_at)) >= 2
ORDER BY active_months DESC;
```

**Expected**: Alice Chen — orders in Nov 2025, Jan 2026, Aug 2026 (3 distinct months).

---

## Problem 6: Payment Method Success Rate

**Question**: For each payment method, calculate the success (COMPLETED) rate as a percentage.

**Solution**:
```sql
SELECT
    method,
    COUNT(*)                                          AS total,
    COUNT(*) FILTER (WHERE status = 'COMPLETED')      AS completed,
    COUNT(*) FILTER (WHERE status IN ('FAILED','REFUNDED')) AS failed_or_refunded,
    COUNT(*) FILTER (WHERE status = 'PENDING')        AS pending,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'COMPLETED') * 100.0
        / NULLIF(COUNT(*), 0),
    1)                                                AS success_rate_pct
FROM payments
GROUP BY method
ORDER BY success_rate_pct DESC NULLS LAST;
```

---

## Problem 7: Orders with Item Count and Average Item Price

**Question**: For each order, show: order ID, customer email, number of distinct products, total items (quantity sum), and average item price.

**Solution**:
```sql
SELECT
    o.id                                        AS order_id,
    c.email,
    o.status,
    COUNT(DISTINCT oi.product_id)               AS distinct_products,
    SUM(oi.quantity)                            AS total_items,
    ROUND(AVG(oi.unit_price)::NUMERIC, 2)       AS avg_item_price,
    o.total                                     AS order_total
FROM orders o
JOIN customers c   ON c.id = o.customer_id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id, c.email, o.status, o.total
ORDER BY distinct_products DESC, o.total DESC;
```

---

## Problem 8: Customers With No Completed Payments (Outstanding Balance)

**Question**: Find customers who have placed at least one order but have no COMPLETED payment on any of them.

**Solution**:
```sql
SELECT
    c.email,
    COUNT(DISTINCT o.id)  AS total_orders,
    SUM(o.total)           AS outstanding_amount
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE NOT EXISTS (
    SELECT 1
    FROM payments p
    WHERE p.order_id = o.id
      AND p.status = 'COMPLETED'
)
GROUP BY c.id, c.email
ORDER BY outstanding_amount DESC;
```

---

## Common Trap Summary

| Trap | Symptom | Fix |
| :--- | :--- | :--- |
| `SUM(col)` returns NULL | Customer with all-NULL amounts shows NULL | Wrap with `COALESCE(SUM(col), 0)` |
| Division by zero in rate calculation | Error on groups with no rows | Use `NULLIF(denominator, 0)` |
| `WHERE` on aggregate result | ERROR: aggregate functions not allowed in WHERE | Move to `HAVING` |
| Row multiplication on 1:N join before aggregate | `SUM(shipping_cost)` counts it N times | Aggregate the N side first in CTE/subquery |
| Customers missing from output | Used `INNER JOIN` instead of `LEFT JOIN` to start from customers | Start from the "all" side with `LEFT JOIN` |
