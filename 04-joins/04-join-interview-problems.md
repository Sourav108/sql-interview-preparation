# 04. Join Interview Problems — 10 Canonical Questions

All queries use the e-commerce dataset from `datasets/ecommerce/`. Load `schema.sql` + `seed.sql` before running.

---

## Problem 1: Customers with No Orders

**Question**: Find all customers who have never placed any order. Return their email and full name.

```sql
-- ✅ Solution (Anti-join using NOT EXISTS — NULL-safe)
SELECT
    c.email,
    c.first_name || ' ' || c.last_name AS full_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.id
)
ORDER BY c.last_name;
```

| email | full_name |
| :--- | :--- |
| karen.hall@example.com | Karen Hall |
| henry.park@example.com | Henry Park |
| leo.santos@example.com | Leo Santos |
| james.wu@example.com | James Wu |

**Follow-up**: *How would you count customers with vs without orders in a single query?*
```sql
SELECT
    COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id)) AS with_orders,
    COUNT(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id)) AS without_orders
FROM customers c;
```

---

## Problem 2: Products Never Sold

**Question**: Find all products that have never appeared in any order item.

```sql
SELECT p.sku, p.name, p.status
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM order_items oi WHERE oi.product_id = p.id
);
```

**Expected**: The discontinued `USB-C Braided Cable` (SKU-CAB-01) — not in any order.

---

## Problem 3: Each Customer's Most Recent Order

**Question**: Find the most recent order (by `placed_at`) for each customer who has at least one order. Return customer email, order ID, and placement date.

```sql
-- Approach A: Correlated subquery (readable)
SELECT
    c.email,
    o.id AS order_id,
    o.placed_at
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE o.placed_at = (
    SELECT MAX(o2.placed_at)
    FROM orders o2
    WHERE o2.customer_id = c.id
);

-- Approach B: Window function (efficient — single scan)
WITH ranked_orders AS (
    SELECT
        c.email,
        o.id         AS order_id,
        o.placed_at,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.placed_at DESC
        ) AS rn
    FROM customers c
    JOIN orders o ON o.customer_id = c.id
)
SELECT email, order_id, placed_at
FROM ranked_orders
WHERE rn = 1
ORDER BY placed_at DESC;
```

**Performance note**: Window function approach scans the table once. Correlated subquery approach executes one `MAX` subquery per customer row. On large tables, the window function is significantly faster.

---

## Problem 4: Employees and Their Managers (Self-Join)

**Fictional extension**: Given an `employees` table with `id`, `first_name`, `manager_id`:

```sql
CREATE TABLE employees (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name  VARCHAR(100) NOT NULL,
    department  VARCHAR(100),
    salary      NUMERIC(10,2),
    manager_id  BIGINT REFERENCES employees(id)
);

INSERT INTO employees (first_name, department, salary, manager_id) VALUES
    ('Priya',   'Engineering', 150000, NULL),     -- id=1, CEO
    ('Rohan',   'Engineering', 120000, 1),         -- id=2, reports to Priya
    ('Sneha',   'Engineering', 110000, 2),         -- id=3, reports to Rohan
    ('Arjun',   'Marketing',   105000, 1),         -- id=4, reports to Priya
    ('Meera',   'Marketing',    95000, 4),          -- id=5, reports to Arjun
    ('Vikram',  'Engineering', 115000, 2);          -- id=6, reports to Rohan

-- Query: All employees with their manager's name
SELECT
    e.first_name                      AS employee,
    e.salary,
    m.first_name                      AS manager,
    m.salary                          AS manager_salary
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id
ORDER BY e.salary DESC;
```

| employee | salary | manager | manager_salary |
| :--- | :--- | :--- | :--- |
| Priya | 150000 | NULL | NULL |
| Rohan | 120000 | Priya | 150000 |
| Vikram | 115000 | Rohan | 120000 |
| Sneha | 110000 | Rohan | 120000 |
| Arjun | 105000 | Priya | 150000 |
| Meera | 95000 | Arjun | 105000 |

**Follow-up**: *Find employees who earn more than their direct manager.*
```sql
SELECT e.first_name AS employee, e.salary, m.first_name AS manager, m.salary AS manager_salary
FROM employees e
JOIN employees m ON m.id = e.manager_id
WHERE e.salary > m.salary;
```

---

## Problem 5: Orders with Their Payment Status

**Question**: List all orders showing the order total and payment status. Include orders that have no payment record (unpaid orders).

```sql
SELECT
    o.id              AS order_id,
    o.status          AS order_status,
    o.total,
    p.status          AS payment_status,
    p.method          AS payment_method,
    p.paid_at
FROM orders o
LEFT JOIN payments p ON p.order_id = o.id
ORDER BY o.placed_at DESC;
```

**Key**: Order 11 (Irene Ross, `DELIVERED`) has no payment row — appears with all payment columns as `NULL`.

---

## Problem 6: Revenue by Product Category

**Question**: Calculate total revenue per product category, only counting DELIVERED orders.

```sql
SELECT
    p.category,
    COUNT(DISTINCT o.id)               AS order_count,
    SUM(oi.quantity)                   AS units_sold,
    SUM(oi.quantity * oi.unit_price)   AS category_revenue
FROM order_items oi
JOIN products p ON p.id = oi.product_id
JOIN orders   o ON o.id = oi.order_id
WHERE o.status = 'DELIVERED'
GROUP BY p.category
ORDER BY category_revenue DESC;
```

---

## Problem 7: Customers Who Ordered Every Product in a Category

**Question**: Using relational division — find customers who have ordered ALL active keyboards.

```sql
WITH keyboard_products AS (
    SELECT id FROM products WHERE category = 'Keyboards' AND status = 'ACTIVE'
),
customer_keyboard_orders AS (
    SELECT DISTINCT o.customer_id, oi.product_id
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE oi.product_id IN (SELECT id FROM keyboard_products)
)
SELECT c.email
FROM customers c
WHERE NOT EXISTS (
    -- "Is there a keyboard product this customer has NOT bought?"
    SELECT 1 FROM keyboard_products kp
    WHERE NOT EXISTS (
        SELECT 1 FROM customer_keyboard_orders cko
        WHERE cko.customer_id = c.id
          AND cko.product_id = kp.id
    )
);
```

**Pattern**: Double `NOT EXISTS` — the **relational division** pattern. *"There is no product for which this customer has not placed an order."*

---

## Problem 8: Three-Way Join with Aggregation

**Question**: For each customer, show total spending, number of orders, and number of distinct products purchased.

```sql
SELECT
    c.email,
    c.first_name,
    COUNT(DISTINCT o.id)          AS orders_placed,
    COUNT(DISTINCT oi.product_id) AS products_purchased,
    SUM(oi.quantity * oi.unit_price) AS total_spending
FROM customers c
JOIN orders o     ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id = o.id
WHERE o.status <> 'CANCELLED'
GROUP BY c.id, c.email, c.first_name
ORDER BY total_spending DESC;
```

---

## Problem 9: Products Ordered Together (Affinity/Basket Analysis)

**Question**: Find pairs of products that have been purchased in the same order, with the co-occurrence count.

```sql
SELECT
    p1.name  AS product_a,
    p2.name  AS product_b,
    COUNT(*) AS co_occurrence_count
FROM order_items oi1
JOIN order_items oi2
    ON  oi2.order_id   = oi1.order_id
    AND oi2.product_id > oi1.product_id    -- Avoid duplicates and self-pairs
JOIN products p1 ON p1.id = oi1.product_id
JOIN products p2 ON p2.id = oi2.product_id
GROUP BY p1.name, p2.name
ORDER BY co_occurrence_count DESC;
```

**Note**: `oi2.product_id > oi1.product_id` is a non-equi join predicate that generates each unordered pair exactly once.

---

## Problem 10: Missing Relationships — Inventory Without a Product

**Question**: A data quality check — find any `inventory` rows whose `product_id` does not match any row in `products`.

```sql
-- Anti-join for referential integrity audit
SELECT inv.product_id, inv.quantity_on_hand
FROM inventory inv
WHERE NOT EXISTS (
    SELECT 1 FROM products p WHERE p.id = inv.product_id
);
-- Expected: 0 rows (if FK constraints are enforced, this is impossible)
-- Useful when constraints are disabled for bulk loads
```

**Follow-up**: *Products with no inventory row:*
```sql
SELECT p.id, p.sku, p.name
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM inventory inv WHERE inv.product_id = p.id
);
```

---

## Summary: Join Pattern Selection Guide

| Requirement | Pattern |
| :--- | :--- |
| Match rows across tables | `INNER JOIN` |
| Preserve left rows, NULL for non-matches | `LEFT JOIN` |
| All rows from both sides | `FULL OUTER JOIN` |
| Existence check only (no column from right side needed) | `WHERE EXISTS` |
| Non-existence check | `WHERE NOT EXISTS` |
| Self-referential hierarchy | `SELF JOIN` with aliases |
| All combinations | `CROSS JOIN` |
| Relational division ("all of") | Double `NOT EXISTS` |
