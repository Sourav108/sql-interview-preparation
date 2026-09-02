# 01. The Aggregation Pipeline

## 1. Problem

Business reporting requires collapsing individual records into summaries. A report of "total revenue per month" needs to group 100,000 order rows into 12 monthly buckets, each with one aggregate number. Aggregation functions and `GROUP BY` are the mechanism.

---

## 2. Concept: Aggregation Functions

Aggregate functions operate on a **set of rows** (a group) and return a single scalar value per group.

### 2.1 COUNT

| Expression | Counts | NULL Handling |
| :--- | :--- | :--- |
| `COUNT(*)` | All rows in the group (including NULLs) | Never ignores any row |
| `COUNT(column)` | Rows where `column IS NOT NULL` | Ignores NULL values |
| `COUNT(DISTINCT column)` | Distinct non-NULL values of `column` | Ignores NULLs + deduplicates |

```sql
-- Demonstrate COUNT semantics using payments table
-- (some payments have NULL paid_at for pending/pending orders)
SELECT
    COUNT(*)                  AS total_payment_rows,   -- all rows
    COUNT(paid_at)            AS rows_with_paid_at,    -- non-NULL paid_at only
    COUNT(DISTINCT method)    AS distinct_methods       -- unique payment methods
FROM payments;
```

| total_payment_rows | rows_with_paid_at | distinct_methods |
| :--- | :--- | :--- |
| 10 | 8 | 5 |

*(2 payments have `paid_at = NULL` — pending payments)*

### 2.2 SUM

```sql
-- NULL behavior: SUM ignores NULLs. SUM of all-NULL group returns NULL (not 0).
SELECT
    SUM(total)       AS gross_revenue,
    SUM(shipping_cost) AS total_shipping
FROM orders
WHERE status <> 'CANCELLED';

-- SUM of no rows (empty group) returns NULL — use COALESCE for safety
SELECT COALESCE(SUM(total), 0) AS gross_revenue
FROM orders
WHERE customer_id = 999;  -- customer does not exist → returns 0, not NULL
```

### 2.3 AVG, MIN, MAX

```sql
SELECT
    AVG(total)::NUMERIC(10,2)   AS avg_order_value,
    MIN(total)                  AS smallest_order,
    MAX(total)                  AS largest_order,
    MIN(placed_at)              AS first_order_date,
    MAX(placed_at)              AS latest_order_date
FROM orders
WHERE status = 'DELIVERED';
```

**NULL rules (all aggregate functions)**:
- Aggregate functions **ignore NULL values** in the column being aggregated.
- If the group has zero non-NULL values, the result is `NULL` (except `COUNT(*)` which returns `0`).

---

## 3. GROUP BY — Defining the Grouping Dimension

`GROUP BY` collapses all rows with the same value(s) in the specified columns into a single output row, then applies aggregate functions within each group.

```sql
-- Revenue and order count grouped by order status
SELECT
    status,
    COUNT(*)        AS order_count,
    SUM(total)      AS total_revenue,
    AVG(total)      AS avg_order_value
FROM orders
GROUP BY status
ORDER BY total_revenue DESC NULLS LAST;
```

### 3.1 The GROUP BY Rule

**Every non-aggregate column in `SELECT` must appear in `GROUP BY`** (or be functionally dependent on the `GROUP BY` key).

```sql
-- ❌ ILLEGAL: first_name is not in GROUP BY and not an aggregate
SELECT department, first_name, AVG(salary)
FROM employees
GROUP BY department;
-- ERROR: column "employees.first_name" must appear in the GROUP BY clause
-- or be used in an aggregate function

-- ✅ Correct: group by both columns
SELECT department, first_name, AVG(salary)
FROM employees
GROUP BY department, first_name;
```

> **[PostgreSQL Specific]**: PostgreSQL allows grouping by the primary key, which makes all other columns of that table functionally dependent:
> ```sql
> -- Legal in PostgreSQL because c.id is the PK (all other c.* columns depend on it)
> SELECT c.id, c.email, c.first_name, COUNT(o.id)
> FROM customers c
> LEFT JOIN orders o ON o.customer_id = c.id
> GROUP BY c.id;
> ```

### 3.2 Composite GROUP BY

```sql
-- Monthly revenue broken down by order status
SELECT
    DATE_TRUNC('month', placed_at)::DATE   AS month,
    status,
    COUNT(*)                               AS order_count,
    SUM(total)                             AS revenue
FROM orders
GROUP BY DATE_TRUNC('month', placed_at), status
ORDER BY month, status;
```

---

## 4. HAVING — Filtering Groups

`HAVING` filters after grouping. It can reference aggregate expressions.

```sql
-- Customers who have spent more than ₹10,000 total (DELIVERED orders only)
SELECT
    c.email,
    COUNT(o.id)   AS order_count,
    SUM(o.total)  AS total_spent
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE o.status = 'DELIVERED'          -- WHERE: filter rows before grouping
GROUP BY c.id, c.email
HAVING SUM(o.total) > 10000           -- HAVING: filter groups after aggregation
ORDER BY total_spent DESC;
```

### 4.1 WHERE vs HAVING — The Critical Distinction

| | `WHERE` | `HAVING` |
| :--- | :--- | :--- |
| **Applied** | Before `GROUP BY` (Step 4) | After `GROUP BY` (Step 6) |
| **Can reference** | Individual column values | Aggregate expressions |
| **Cannot reference** | Aggregate functions | (can reference them) |
| **Performance** | Better — reduces rows before grouping | Worse — groups all rows, then filters |

**Performance rule**: Always `WHERE` what you can. Use `HAVING` only for conditions that require the aggregated value.

```sql
-- ❌ Inefficient: filtering by status in HAVING after grouping all rows
SELECT status, COUNT(*)
FROM orders
GROUP BY status
HAVING status = 'DELIVERED';

-- ✅ Efficient: filter by status in WHERE before grouping
SELECT status, COUNT(*)
FROM orders
WHERE status = 'DELIVERED'
GROUP BY status;
```

---

## 5. NULL Behavior in Aggregation

```sql
-- GROUP BY treats NULL as a group unto itself
-- All rows with NULL value in the grouping column form their own group
INSERT INTO orders (customer_id, status, shipping_address, total, placed_at)
VALUES (12, 'DELIVERED', 'Rollback Test', 1.00, NOW());
-- (Hypothetical — to test NULL grouping behavior)

-- In practice:
SELECT
    COALESCE(category, 'Uncategorized') AS category,
    COUNT(*) AS product_count
FROM products
GROUP BY category;
-- NULLs in category column would form a separate group labeled NULL
-- COALESCE converts them to a readable label
```

---

## 6. Interview Questions

**Q1: What is the difference between `COUNT(*)`, `COUNT(column)`, and `COUNT(DISTINCT column)`?**
`COUNT(*)` counts all rows in the group including those with NULLs — it never ignores a row. `COUNT(column)` counts only rows where that column is not NULL — it ignores NULL values. `COUNT(DISTINCT column)` counts the number of unique non-NULL values. Example: if `paid_at` is NULL for 2 pending payments in a 10-row table, `COUNT(*)` = 10, `COUNT(paid_at)` = 8, and `COUNT(DISTINCT method)` = the count of unique payment methods used.

**Q2: You need to filter for groups with more than 5 orders. Should you use `WHERE` or `HAVING`?**
`HAVING`. The condition `COUNT(*) > 5` is an aggregate expression — it applies to the group as a whole, not to individual rows. `WHERE` runs before `GROUP BY` and cannot reference aggregate functions. `HAVING` runs after `GROUP BY` and can filter on `COUNT(*)`, `SUM()`, `AVG()`, or any other aggregate result.

**Q3: What does `SUM(col)` return when the group contains only NULL values?**
`NULL`. Aggregate functions (including `SUM`, `AVG`, `MIN`, `MAX`) ignore NULLs and return `NULL` when the input set has no non-NULL values — not `0`. This is a common bug: `SUM(amount)` for a customer who has only NULL-amount rows returns `NULL`, which is unexpected in a financial report. Always use `COALESCE(SUM(amount), 0)` when a zero default is meaningful.

**Q4: What is a GROUP BY functional dependency, and when is it relevant?**
Functional dependency means that knowing the value of column A uniquely determines the value of column B. When you `GROUP BY` a table's primary key, all other columns of that table are functionally dependent on the PK — the database can include them in `SELECT` without requiring them in `GROUP BY`. PostgreSQL and SQL:2023 support this; MySQL requires explicit `GROUP BY` listing. This matters when you join and group: `GROUP BY c.id` allows `SELECT c.email, c.first_name` without repeating those in `GROUP BY`.

---

## 7. Further Reading
- [PostgreSQL 18 Documentation: Aggregate Functions](https://www.postgresql.org/docs/18/functions-aggregate.html)
- [PostgreSQL 18 Documentation: GROUP BY and HAVING](https://www.postgresql.org/docs/18/queries-table-expressions.html#QUERIES-GROUP)
