# 02. WHERE Clause and Predicate Reference

## 1. Concept

The `WHERE` clause filters rows **after** `FROM`/`JOIN` but **before** `GROUP BY`. Every predicate in `WHERE` evaluates to `TRUE`, `FALSE`, or `UNKNOWN`. Only rows where the entire predicate evaluates to `TRUE` are retained.

---

## 2. Complete Predicate Reference

### 2.1 Comparison Operators

| Operator | Meaning | Notes |
| :--- | :--- | :--- |
| `=` | Equal to | `NULL = NULL` evaluates to `UNKNOWN`, not `TRUE` |
| `<>` or `!=` | Not equal to | `NULL <> 5` evaluates to `UNKNOWN` |
| `<`, `<=`, `>`, `>=` | Less/greater than | `NULL < 5` evaluates to `UNKNOWN` |
| `IS NULL` | True if value is NULL | The only correct NULL equality test |
| `IS NOT NULL` | True if value is not NULL | |
| `IS DISTINCT FROM` | Null-safe equality | `NULL IS DISTINCT FROM NULL` → `FALSE` |
| `IS NOT DISTINCT FROM` | Null-safe inequality | `NULL IS NOT DISTINCT FROM NULL` → `TRUE` |

### 2.2 Range: `BETWEEN`

```sql
-- [Standard SQL]
-- BETWEEN is INCLUSIVE on both ends
SELECT id, total
FROM orders
WHERE total BETWEEN 1000 AND 5000;
-- Equivalent to: WHERE total >= 1000 AND total <= 5000

-- Date ranges: use explicit bounds for TIMESTAMPTZ precision
SELECT id, placed_at
FROM orders
WHERE placed_at >= '2026-09-01 00:00:00+00'
  AND placed_at <  '2026-10-01 00:00:00+00';
-- Preferred over: WHERE DATE_TRUNC('month', placed_at) = '2026-09-01'
-- Reason: The sargable range keeps index seek; DATE_TRUNC() on indexed column forces Seq Scan
```

### 2.3 Set Membership: `IN` and `NOT IN`

```sql
-- IN: tests membership in a fixed set of values
SELECT id, status FROM orders
WHERE status IN ('PENDING', 'CONFIRMED', 'SHIPPED');

-- NOT IN: excludes values — DANGEROUS with NULLs!
-- If any value in the list is NULL, NOT IN returns UNKNOWN for every row → empty result
SELECT id FROM orders
WHERE status NOT IN ('CANCELLED', NULL);  -- Returns 0 rows! NOT IN + NULL trap
-- ✅ Fix: use explicit IS NOT NULL guard or NOT EXISTS
SELECT id FROM orders
WHERE status <> 'CANCELLED';  -- Safe two-value comparison

-- IN with subquery
SELECT id FROM customers
WHERE id IN (SELECT customer_id FROM orders WHERE total > 10000);
```

> ⚠️ **Critical Interview Trap — `NOT IN` with NULLs**: See [Module 09](../09-null-and-three-valued-logic/) for the complete 3-valued logic treatment.

### 2.4 Pattern Matching: `LIKE` and `ILIKE`

```sql
-- LIKE: case-sensitive pattern matching
-- %  matches zero or more characters
-- _  matches exactly one character
SELECT email FROM customers WHERE email LIKE '%@example.com';
SELECT name  FROM products  WHERE name  LIKE 'USB-_';

-- [PostgreSQL Specific] ILIKE: case-insensitive LIKE
SELECT email FROM customers WHERE email ILIKE '%@EXAMPLE.COM';

-- Leading wildcard (%foo) CANNOT use a standard B-Tree index!
-- PostgreSQL requires pg_trgm GIN index for efficient substring search.
-- [PostgreSQL Specific]:
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_products_name_trgm ON products USING GIN (name gin_trgm_ops);
```

### 2.5 Boolean Logic

```sql
-- AND has higher precedence than OR — use parentheses explicitly
SELECT id FROM orders
WHERE (status = 'PENDING' OR status = 'CONFIRMED')
  AND total > 5000;

-- NOT negation
SELECT id FROM products WHERE NOT (status = 'DISCONTINUED');
-- Equivalent: WHERE status <> 'DISCONTINUED'
-- But: NULL status rows still excluded by both (UNKNOWN <> 'DISCONTINUED' → UNKNOWN)
```

---

## 3. `DISTINCT` — Deduplicate Result Rows

```sql
-- Returns each unique status value — fine usage
SELECT DISTINCT status FROM orders;

-- ⚠️ Trap: DISTINCT on full row after a wide join is expensive and often masks a bug
SELECT DISTINCT c.email, o.total
FROM customers c
JOIN orders o ON o.customer_id = c.id;
-- If you're getting duplicates here, the join itself is wrong, not missing DISTINCT
```

---

## 4. `ORDER BY` — Sorting and NULL Ordering

```sql
-- [Standard SQL] Sort orders by recency
SELECT id, placed_at, total
FROM orders
ORDER BY placed_at DESC;

-- Sort by multiple columns: primary then secondary sort
SELECT id, status, total
FROM orders
ORDER BY status ASC, total DESC;

-- [PostgreSQL Specific] NULLS FIRST / NULLS LAST
-- In DESC order, NULLs appear first by default in PostgreSQL
-- In ASC order, NULLs appear last by default
SELECT id, paid_at FROM payments
ORDER BY paid_at ASC NULLS FIRST;   -- NULL paid_at (pending) appear at top

-- SQL Standard: NULLS FIRST and NULLS LAST (also supported by Oracle, PostgreSQL)
-- MySQL does NOT support NULLS FIRST/LAST syntax directly
```

---

## 5. `LIMIT` and `OFFSET` — Pagination

```sql
-- Return first 10 orders
SELECT id, placed_at, total
FROM orders
ORDER BY placed_at DESC
LIMIT 10;

-- Page 3 of 10 items per page
SELECT id, placed_at, total
FROM orders
ORDER BY placed_at DESC
LIMIT 10 OFFSET 20;  -- Skip 20, return next 10

-- ⚠️ Performance trap: OFFSET 1000000 LIMIT 10 requires reading 1,000,010 rows
-- Use keyset pagination for deep pages — covered in Module 17
```

> **[Standard SQL Alternative]**: `FETCH FIRST 10 ROWS ONLY` (SQL:2008 standard — supported by PostgreSQL, Oracle, SQL Server, DB2). MySQL uses `LIMIT` only.

---

## 6. Column Aliases and Expressions

```sql
-- Computed expressions in SELECT
SELECT
    id,
    first_name || ' ' || last_name         AS full_name,        -- String concatenation
    UPPER(email)                            AS email_upper,
    EXTRACT(YEAR FROM created_at)           AS signup_year,
    (CURRENT_DATE - created_at::DATE)       AS days_since_signup
FROM customers
WHERE created_at >= '2026-01-01';
```

---

## 7. Full Query Example

Using the e-commerce schema: find all active customers who signed up in 2026, ordered by most recent, showing their email and days since registration:

```sql
SELECT
    c.email,
    c.first_name || ' ' || c.last_name            AS full_name,
    c.created_at::DATE                             AS signup_date,
    CURRENT_DATE - c.created_at::DATE              AS days_since_signup
FROM customers c
WHERE c.created_at >= '2026-01-01 00:00:00+00'
  AND c.created_at <  '2027-01-01 00:00:00+00'
ORDER BY c.created_at DESC
LIMIT 20;
```

---

## 8. Interview Questions

**Q1: What is the difference between `LIKE` and `ILIKE` in PostgreSQL?**
`LIKE` performs case-sensitive pattern matching per the SQL standard. `ILIKE` is a PostgreSQL extension that performs case-insensitive matching. For portable SQL, use `WHERE LOWER(column) LIKE LOWER(pattern)` instead of `ILIKE`. Neither can use a standard B-Tree index when the pattern starts with `%`; the `pg_trgm` extension with a GIN index enables efficient substring lookups.

**Q2: Why is `WHERE total BETWEEN 1000 AND 5000` inclusive of both bounds?**
`BETWEEN` in SQL is equivalent to `>= lower_bound AND <= upper_bound`. Both 1000 and 5000 are included. This is a source of date-range bugs: `WHERE order_date BETWEEN '2026-09-01' AND '2026-09-30'` misses orders at `2026-09-30 23:59:59`. The safe pattern for timestamps is always `>= start AND < exclusive_end`.

**Q3: Why does `NOT IN (SELECT ...)` sometimes return zero rows?**
The `NOT IN` predicate uses equality comparison, which produces `UNKNOWN` when compared against `NULL`. If the subquery returns even a single `NULL` value, every row comparison with `NOT IN` evaluates to `UNKNOWN`, resulting in zero rows passing the filter. Use `NOT EXISTS (SELECT 1 FROM ... WHERE ...)` instead — `EXISTS` checks for row existence without NULL-sensitive equality comparisons.

---

## 9. Further Reading
- [PostgreSQL 18 Documentation: SELECT](https://www.postgresql.org/docs/18/sql-select.html)
- [PostgreSQL 18 Documentation: Pattern Matching](https://www.postgresql.org/docs/18/functions-matching.html)
- [Use The Index, Luke: Partial Indexes](https://use-the-index-luke.com/sql/where-clause/partial-and-filtered-indexes)
