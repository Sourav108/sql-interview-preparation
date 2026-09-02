# 02. Conditional Aggregation and Business Reporting

## 1. Problem

Real business queries rarely aggregate all rows uniformly. You need answers like:
- *"How many orders were DELIVERED vs CANCELLED per month?"*
- *"What is the completion rate per payment method?"*
- *"Show revenue split by product category in a single row per month."*

These require **conditional aggregation** — applying different conditions inside the same aggregate function.

---

## 2. Concept: Two Equivalent Approaches

### 2.1 `CASE` Inside an Aggregate (Standard SQL)

```sql
-- [Standard SQL]
SELECT
    COUNT(*)                                              AS total_orders,
    COUNT(CASE WHEN status = 'DELIVERED' THEN 1 END)     AS delivered,
    COUNT(CASE WHEN status = 'CANCELLED' THEN 1 END)     AS cancelled,
    COUNT(CASE WHEN status = 'PENDING'   THEN 1 END)     AS pending,
    SUM  (CASE WHEN status = 'DELIVERED' THEN total END) AS delivered_revenue
FROM orders;
```

*How it works*: The `CASE` expression returns `1` (or the value) when the condition matches, and `NULL` otherwise. Since aggregate functions ignore `NULL`, only the matching rows contribute.

### 2.2 `FILTER (WHERE ...)` Clause (SQL:2003 Standard, PostgreSQL)

```sql
-- [Standard SQL — also PostgreSQL Specific in wide adoption]
-- Cleaner, more readable, and slightly faster in some plans
SELECT
    COUNT(*)                                    AS total_orders,
    COUNT(*) FILTER (WHERE status = 'DELIVERED') AS delivered,
    COUNT(*) FILTER (WHERE status = 'CANCELLED') AS cancelled,
    COUNT(*) FILTER (WHERE status = 'PENDING')   AS pending,
    SUM(total) FILTER (WHERE status = 'DELIVERED') AS delivered_revenue
FROM orders;
```

**Expected result** (from seed data):

| total_orders | delivered | cancelled | pending | delivered_revenue |
| :--- | :--- | :--- | :--- | :--- |
| 11 | 6 | 1 | 2 | 59050.00 |

> **[PostgreSQL Specific]**: The `FILTER (WHERE ...)` clause is supported in PostgreSQL, DuckDB, and SQLite. MySQL and older SQL Server do not support it — use `CASE` for cross-database compatibility.

---

## 3. Monthly Status Breakdown (Pivot-Style)

```sql
SELECT
    DATE_TRUNC('month', placed_at)::DATE        AS month,
    COUNT(*)                                     AS total_orders,
    COUNT(*) FILTER (WHERE status = 'DELIVERED') AS delivered,
    COUNT(*) FILTER (WHERE status = 'SHIPPED')   AS shipped,
    COUNT(*) FILTER (WHERE status = 'CONFIRMED') AS confirmed,
    COUNT(*) FILTER (WHERE status = 'PENDING')   AS pending,
    COUNT(*) FILTER (WHERE status = 'CANCELLED') AS cancelled,
    SUM(total)                                   AS total_gmv,
    SUM(total) FILTER (WHERE status = 'DELIVERED') AS confirmed_revenue
FROM orders
GROUP BY DATE_TRUNC('month', placed_at)
ORDER BY month;
```

---

## 4. Completion Rate per Payment Method

```sql
SELECT
    method,
    COUNT(*)                                         AS total_attempts,
    COUNT(*) FILTER (WHERE status = 'COMPLETED')     AS completed,
    COUNT(*) FILTER (WHERE status = 'FAILED')        AS failed,
    COUNT(*) FILTER (WHERE status = 'REFUNDED')      AS refunded,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'COMPLETED') * 100.0
        / NULLIF(COUNT(*), 0),
    2)                                               AS completion_pct
FROM payments
GROUP BY method
ORDER BY completion_pct DESC;
```

**Note**: `NULLIF(COUNT(*), 0)` prevents division-by-zero if a method has no rows in the filtered dataset.

---

## 5. Running Totals Using Aggregation (Without Window Functions)

Window functions (Module 07) are the clean solution for running totals. However, you may be asked to do it with pure aggregation using a self-join:

```sql
-- Running cumulative revenue per month (aggregation approach — less efficient)
SELECT
    a.month,
    a.monthly_revenue,
    SUM(b.monthly_revenue) AS cumulative_revenue
FROM (
    SELECT
        DATE_TRUNC('month', placed_at)::DATE AS month,
        SUM(total)                            AS monthly_revenue
    FROM orders WHERE status = 'DELIVERED'
    GROUP BY 1
) a
JOIN (
    SELECT
        DATE_TRUNC('month', placed_at)::DATE AS month,
        SUM(total)                            AS monthly_revenue
    FROM orders WHERE status = 'DELIVERED'
    GROUP BY 1
) b ON b.month <= a.month
GROUP BY a.month, a.monthly_revenue
ORDER BY a.month;
-- The self-join approach is O(N²) — always prefer window functions for this
```

---

## 6. Business KPI Examples

### 6.1 Average Order Value (AOV)

```sql
SELECT
    ROUND(SUM(total)::NUMERIC / NULLIF(COUNT(*), 0), 2) AS aov
FROM orders
WHERE status IN ('DELIVERED', 'SHIPPED', 'CONFIRMED');
```

### 6.2 Revenue and Orders by Customer Tier

```sql
WITH customer_spending AS (
    SELECT
        c.id,
        c.email,
        SUM(o.total) AS total_spent
    FROM customers c
    JOIN orders o ON o.customer_id = c.id
    WHERE o.status <> 'CANCELLED'
    GROUP BY c.id, c.email
)
SELECT
    CASE
        WHEN total_spent >= 15000 THEN 'Platinum'
        WHEN total_spent >= 8000  THEN 'Gold'
        WHEN total_spent >= 3000  THEN 'Silver'
        ELSE 'Bronze'
    END                 AS tier,
    COUNT(*)            AS customer_count,
    SUM(total_spent)    AS tier_revenue,
    ROUND(AVG(total_spent)::NUMERIC, 2) AS avg_spending
FROM customer_spending
GROUP BY 1
ORDER BY tier_revenue DESC;
```

### 6.3 Daily Active Users (DAU)

```sql
-- "Active" = placed at least one order on that day
SELECT
    placed_at::DATE     AS activity_date,
    COUNT(DISTINCT customer_id) AS daily_active_customers
FROM orders
WHERE placed_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY placed_at::DATE
ORDER BY activity_date;
```

---

## 7. Interview Questions

**Q1: When would you use `FILTER (WHERE ...)` vs `CASE WHEN ... THEN ... END` inside an aggregate?**
Both produce identical results. `FILTER (WHERE ...)` is more readable, conveys intent directly, and can be marginally faster because the database can skip evaluating the expression for filtered-out rows at the engine level. Use `FILTER` in PostgreSQL for new code. Use `CASE` for cross-database portability (MySQL, older SQL Server do not support `FILTER`).

**Q2: What does `COUNT(*) FILTER (WHERE status = 'COMPLETED')` return if no rows match the filter?**
`0`. This is a key difference from column aggregates: `COUNT(*)` always returns a number, even for empty groups. Compare with `SUM(amount) FILTER (WHERE status = 'COMPLETED')` — that returns `NULL` for an empty filtered group, not `0`. Use `COALESCE(SUM(...) FILTER (...), 0)` when you need zero instead of NULL.

**Q3: How do you compute a percentage breakdown within a single GROUP BY query?**
Use `SUM(total) / NULLIF(SUM(SUM(total)) OVER (), 0)` or a CTE approach. The simplest production pattern:
```sql
SUM(total) FILTER (WHERE status = 'DELIVERED') * 100.0 / NULLIF(SUM(total), 0)
```
Always use `NULLIF(denominator, 0)` to prevent division by zero when a group has no revenue.

---

## 8. Further Reading
- [PostgreSQL 18 Documentation: Aggregate Functions with FILTER](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-AGGREGATES)
- [PostgreSQL 18 Documentation: Date/Time Functions](https://www.postgresql.org/docs/18/functions-datetime.html)
