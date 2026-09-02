# 01. CASE Expressions, COALESCE, NULLIF, and Type Casting

## 1. CASE Expression Syntax

CASE is a row-level conditional expression — not a statement. It evaluates to a single value per row and can appear anywhere an expression is valid: `SELECT`, `WHERE`, `ORDER BY`, `GROUP BY`, `HAVING`.

### 1.1 Simple CASE (Equality Switch)

```sql
-- [Standard SQL]
-- Maps a single column's values to output labels
SELECT
    id,
    status,
    CASE status
        WHEN 'PENDING'   THEN 'Awaiting Processing'
        WHEN 'CONFIRMED' THEN 'Confirmed by Seller'
        WHEN 'SHIPPED'   THEN 'In Transit'
        WHEN 'DELIVERED' THEN 'Completed'
        WHEN 'CANCELLED' THEN 'Cancelled'
        ELSE 'Unknown Status'
    END AS status_label
FROM orders;
```

### 1.2 Searched CASE (Arbitrary Predicates)

```sql
-- Each WHEN branch evaluates an independent boolean predicate
SELECT
    id,
    total,
    CASE
        WHEN total >= 15000 THEN 'Platinum'
        WHEN total >= 8000  THEN 'Gold'
        WHEN total >= 3000  THEN 'Silver'
        ELSE 'Bronze'
    END AS order_tier
FROM orders
WHERE status = 'DELIVERED';
```

**Short-circuit evaluation**: CASE evaluates branches top-to-bottom and stops at the first `TRUE`. This means: (1) order matters — put the most selective condition first; (2) later branches implicitly exclude all prior conditions.

---

## 2. CASE in Conditional Aggregation

This is the bridge between CASE and aggregation from Module 05:

```sql
-- Single-pass pivot: orders broken down by status in one row per month
SELECT
    DATE_TRUNC('month', placed_at)::DATE AS month,
    COUNT(*)                              AS total_orders,
    SUM(CASE WHEN status = 'DELIVERED' THEN total ELSE 0 END) AS delivered_revenue,
    SUM(CASE WHEN status = 'CANCELLED' THEN total ELSE 0 END) AS cancelled_gmv,
    -- Preferred PostgreSQL syntax using FILTER:
    COUNT(*) FILTER (WHERE status = 'PENDING')   AS pending_count
FROM orders
GROUP BY DATE_TRUNC('month', placed_at)
ORDER BY month;
```

---

## 3. CASE in ORDER BY — Custom Sort Order

```sql
-- Sort orders: PENDING first, then CONFIRMED, then SHIPPED, then DELIVERED, CANCELLED last
SELECT id, status, placed_at
FROM orders
ORDER BY
    CASE status
        WHEN 'PENDING'   THEN 1
        WHEN 'CONFIRMED' THEN 2
        WHEN 'SHIPPED'   THEN 3
        WHEN 'DELIVERED' THEN 4
        WHEN 'CANCELLED' THEN 5
        ELSE 6
    END,
    placed_at DESC;
```

---

## 4. COALESCE — First Non-NULL Value

```sql
-- [Standard SQL]
-- Returns the first non-NULL argument
SELECT
    customer_id,
    COALESCE(phone, email, 'no contact info') AS best_contact
FROM customers;

-- Default value substitution in aggregates
SELECT
    customer_id,
    COALESCE(SUM(total), 0) AS total_spent   -- returns 0 instead of NULL for empty groups
FROM orders
WHERE status = 'DELIVERED'
GROUP BY customer_id;

-- Chaining: prefer address_override over shipping_address
SELECT COALESCE(address_override, shipping_address) AS delivery_address
FROM orders;
```

---

## 5. NULLIF — Convert a Specific Value to NULL

```sql
-- [Standard SQL]
-- NULLIF(a, b): returns NULL if a = b, else returns a
-- Primary use: preventing division by zero
SELECT
    SUM(total) / NULLIF(COUNT(*), 0) AS average_order_value
FROM orders
WHERE status = 'DELIVERED';
-- If COUNT(*) = 0 (no delivered orders), NULLIF returns NULL → division returns NULL (not error)

-- Convert sentinel values to NULL for clean aggregation
SELECT AVG(NULLIF(response_time_ms, -1)) AS avg_response_time
FROM api_logs;
-- -1 often means "timeout" — exclude it from the average
```

---

## 6. GREATEST and LEAST

```sql
-- [Standard SQL]
-- GREATEST: max of argument list (ignores NULLs if any non-NULL exists)
-- LEAST:    min of argument list (ignores NULLs if any non-NULL exists)
SELECT
    GREATEST(shipping_cost, 50)  AS min_charge,    -- charge at least 50
    LEAST(discount_pct, 0.30)    AS capped_discount -- cap discount at 30%
FROM orders;

-- Use case: enforce floor/ceiling without CASE verbosity
```

---

## 7. Type Casting

```sql
-- [Standard SQL]
SELECT CAST('2026-09-02' AS DATE);
SELECT CAST(42 AS TEXT);
SELECT CAST('3.14' AS NUMERIC(10,2));

-- [PostgreSQL Specific] :: shorthand (much more common in PostgreSQL code)
SELECT '2026-09-02'::DATE;
SELECT 42::TEXT;
SELECT '3.14'::NUMERIC(10,2);
SELECT NOW()::DATE;               -- timestamp → date (strips time component)
SELECT '2026-09-02'::TIMESTAMPTZ; -- date string → timestamptz

-- Implicit vs Explicit casting
-- PostgreSQL auto-casts in many contexts but explicit casting avoids surprises:
SELECT '5'::INTEGER + 3;   -- 8 (explicit)
SELECT '5' + 3;            -- PostgreSQL tries to cast '5' → may error depending on context
```

---

## 8. Practical Examples

### 8.1 Customer Classification Report

```sql
WITH customer_revenue AS (
    SELECT
        c.id,
        c.email,
        c.first_name || ' ' || c.last_name AS name,
        COALESCE(SUM(o.total), 0)           AS lifetime_value,
        COUNT(o.id)                         AS order_count
    FROM customers c
    LEFT JOIN orders o
        ON o.customer_id = c.id AND o.status NOT IN ('CANCELLED')
    GROUP BY c.id, c.email, c.first_name, c.last_name
)
SELECT
    name,
    email,
    lifetime_value,
    order_count,
    CASE
        WHEN lifetime_value = 0    THEN 'Never Purchased'
        WHEN lifetime_value < 5000 THEN 'Bronze'
        WHEN lifetime_value < 12000 THEN 'Silver'
        WHEN lifetime_value < 20000 THEN 'Gold'
        ELSE 'Platinum'
    END AS customer_tier,
    CASE
        WHEN order_count = 0 THEN 'Dormant'
        WHEN order_count = 1 THEN 'One-Time'
        ELSE 'Repeat'
    END AS customer_type
FROM customer_revenue
ORDER BY lifetime_value DESC;
```

---

## 9. Interview Questions

**Q1: What is the difference between Simple CASE and Searched CASE?**
Simple CASE (`CASE column WHEN val THEN ...`) performs equality checks against a single expression — equivalent to a switch statement. Searched CASE (`CASE WHEN predicate THEN ...`) evaluates independent boolean predicates in each branch — equivalent to if/else if chains. Searched CASE is more powerful: it can compare different columns, use range conditions (`WHEN salary BETWEEN 50000 AND 100000`), and mix logical operators.

**Q2: How does short-circuit evaluation affect CASE branch ordering?**
CASE evaluates branches top-to-bottom and returns the first `TRUE` branch. Later branches implicitly assume all prior conditions were `FALSE`. This means: (1) order tiers should go from highest to lowest (if `total >= 15000` is checked first, `total >= 8000` in the next branch only sees customers below 15000); (2) you can avoid redundant `AND` conditions by relying on fall-through; (3) performance-sensitive predicates (cheap comparisons) should appear first.

**Q3: When would you use NULLIF over a CASE expression?**
`NULLIF(a, b)` is a concise shorthand for `CASE WHEN a = b THEN NULL ELSE a END`. Use `NULLIF` when converting a single sentinel value to `NULL` (e.g., `-1` timeout, `0` zero-divisor, `''` empty string). Use a full CASE expression when the logic is more complex — converting multiple values, applying range conditions, or returning values other than NULL.

---

## 10. Further Reading
- [PostgreSQL 18 Documentation: Conditional Expressions](https://www.postgresql.org/docs/18/functions-conditional.html)
- [PostgreSQL 18 Documentation: Type Casting](https://www.postgresql.org/docs/18/sql-expressions.html#SQL-SYNTAX-TYPE-CASTS)
