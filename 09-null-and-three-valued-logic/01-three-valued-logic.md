# 01. NULL and Three-Valued Logic

## 1. Problem

`NULL` is not a value — it is the **absence of a known value**. SQL uses Kleene's three-valued logic (3VL) to handle it, which means every predicate can evaluate to `TRUE`, `FALSE`, or `UNKNOWN`. Any predicate comparison involving `NULL` produces `UNKNOWN`, not `FALSE`. This is the root cause of many production bugs.

---

## 2. The Three-Valued Truth Tables

### AND

| A | B | A AND B |
| :--- | :--- | :--- |
| TRUE | TRUE | **TRUE** |
| TRUE | FALSE | **FALSE** |
| TRUE | UNKNOWN | **UNKNOWN** |
| FALSE | TRUE | **FALSE** |
| FALSE | FALSE | **FALSE** |
| FALSE | UNKNOWN | **FALSE** ← NULL suppressed by FALSE |
| UNKNOWN | UNKNOWN | **UNKNOWN** |

### OR

| A | B | A OR B |
| :--- | :--- | :--- |
| TRUE | TRUE | **TRUE** |
| TRUE | FALSE | **TRUE** |
| TRUE | UNKNOWN | **TRUE** ← NULL suppressed by TRUE |
| FALSE | FALSE | **FALSE** |
| FALSE | UNKNOWN | **UNKNOWN** |
| UNKNOWN | UNKNOWN | **UNKNOWN** |

### NOT

| A | NOT A |
| :--- | :--- |
| TRUE | **FALSE** |
| FALSE | **TRUE** |
| UNKNOWN | **UNKNOWN** ← NOT NULL is still UNKNOWN |

**The critical rule**: `WHERE` passes rows only when the predicate is `TRUE`. `UNKNOWN` rows are **discarded**, just like `FALSE` rows.

---

## 3. NULL Comparison Semantics

```sql
-- Every equality/inequality comparison with NULL → UNKNOWN
SELECT NULL = NULL;      -- UNKNOWN (not TRUE!)
SELECT NULL <> NULL;     -- UNKNOWN
SELECT NULL = 5;         -- UNKNOWN
SELECT NULL <> 5;        -- UNKNOWN
SELECT NULL > 5;         -- UNKNOWN
SELECT NOT NULL;         -- UNKNOWN

-- Correct NULL tests
SELECT NULL IS NULL;          -- TRUE ✅
SELECT NULL IS NOT NULL;      -- FALSE ✅
SELECT 5    IS NULL;          -- FALSE ✅
SELECT 5    IS NOT NULL;      -- TRUE ✅

-- [Standard SQL] NULL-safe equality: IS DISTINCT FROM
SELECT NULL IS DISTINCT FROM NULL;      -- FALSE (they are NOT distinct — both unknown)
SELECT NULL IS DISTINCT FROM 5;         -- TRUE
SELECT 5    IS DISTINCT FROM 5;         -- FALSE
SELECT 5    IS NOT DISTINCT FROM NULL;  -- FALSE
```

---

## 4. NULL in WHERE Clauses

```sql
-- payments table has NULL paid_at for pending payments
-- This correctly finds pending payments:
SELECT id FROM payments WHERE paid_at IS NULL;

-- This finds NO rows — even though NULLs exist:
SELECT id FROM payments WHERE paid_at = NULL;   -- ❌ always UNKNOWN → 0 rows
SELECT id FROM payments WHERE paid_at <> NULL;  -- ❌ always UNKNOWN → 0 rows

-- Negation trap: NOT (paid_at IS NULL) ≠ paid_at IS NOT NULL → actually it IS equal
-- But: NOT (paid_at = 5) for a NULL paid_at → UNKNOWN → row dropped
```

---

## 5. The NOT IN + NULL Trap (Critical Interview Topic)

```sql
-- Hypothetical: orders table has a row with NULL customer_id
-- Even one NULL in the subquery result breaks NOT IN entirely

-- Setup: create an orphaned order
INSERT INTO orders (customer_id, status, shipping_address, total, placed_at)
OVERRIDING SYSTEM VALUE
VALUES (NULL, 'PENDING', 'Test', 100, NOW());
-- (This would violate our NOT NULL constraint — but demonstrates the trap conceptually)

-- ❌ Broken: if subquery returns ANY NULL
SELECT email FROM customers
WHERE id NOT IN (SELECT customer_id FROM orders);
-- Logical expansion: id NOT IN (1, 2, 3, NULL)
-- = id<>1 AND id<>2 AND id<>3 AND id<>NULL
-- = TRUE  AND TRUE  AND TRUE  AND UNKNOWN
-- = UNKNOWN → row discarded
-- Result: ZERO rows — complete silent failure

-- ✅ Fix A: NOT EXISTS (always NULL-safe)
SELECT email FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- ✅ Fix B: Explicit NULL guard in subquery
SELECT email FROM customers
WHERE id NOT IN (
    SELECT customer_id FROM orders WHERE customer_id IS NOT NULL
);
```

---

## 6. NULL in Joins

```sql
-- NULLs in join columns never match each other
-- If payments.order_id is NULL for any row, it will never join to orders.id
-- (order_id IS NULL → join predicate is UNKNOWN → row excluded from INNER JOIN)

-- LEFT JOIN produces NULL-extended rows when no match — use IS NULL to detect:
SELECT o.id, p.id AS payment_id
FROM orders o
LEFT JOIN payments p ON p.order_id = o.id
WHERE p.id IS NULL;   -- Orders with no payment
```

---

## 7. NULL in Aggregates

```sql
-- All aggregate functions except COUNT(*) ignore NULLs
SELECT
    COUNT(*)           AS total_rows,       -- counts ALL rows
    COUNT(paid_at)     AS non_null_paid_at, -- ignores NULL paid_at
    SUM(amount)        AS total_amount,     -- ignores NULLs, may return NULL if all NULL
    AVG(amount)        AS avg_amount        -- denominator = count of non-NULL rows only
FROM payments;

-- AVG trap: AVG(amount) divides by the count of non-NULL rows
-- This can skew averages if NULLs represent a meaningful zero
-- Fix: AVG(COALESCE(amount, 0)) — treats NULL as 0 in the average
```

---

## 8. NULL in Sorting

```sql
-- [Standard SQL / PostgreSQL]
-- In ASC order, NULLs appear LAST by default in PostgreSQL
-- In DESC order, NULLs appear FIRST by default in PostgreSQL

SELECT id, paid_at FROM payments ORDER BY paid_at ASC;
-- NULLs at the bottom (last)

SELECT id, paid_at FROM payments ORDER BY paid_at ASC NULLS FIRST;
-- NULLs at the top

SELECT id, paid_at FROM payments ORDER BY paid_at DESC NULLS LAST;
-- NULLs at the bottom, recent payments at top

-- MySQL: NULLs are always FIRST in ASC, LAST in DESC
-- SQL Server: NULLs are always FIRST in ASC, LAST in DESC
-- Oracle: NULLS LAST is the default for ASC (opposite of MySQL)
```

---

## 9. NULL in UNIQUE Constraints

```sql
-- [PostgreSQL / Standard SQL behavior]
-- A UNIQUE constraint allows multiple NULL values — NULLs are considered DISTINCT
-- (because NULL IS DISTINCT FROM NULL)
CREATE TABLE test_unique (val INTEGER UNIQUE);
INSERT INTO test_unique VALUES (NULL);
INSERT INTO test_unique VALUES (NULL);  -- ✅ Succeeds! Two NULLs allowed.
INSERT INTO test_unique VALUES (1);
INSERT INTO test_unique VALUES (1);     -- ❌ Fails: duplicate value 1

-- [PostgreSQL Specific — 15+] NULLS NOT DISTINCT option:
CREATE TABLE test_unique_strict (val INTEGER UNIQUE NULLS NOT DISTINCT);
INSERT INTO test_unique_strict VALUES (NULL);
INSERT INTO test_unique_strict VALUES (NULL);  -- ❌ Fails: NULL treated as equal to NULL
```

---

## 10. NULL Handling Functions

```sql
-- COALESCE: returns first non-NULL argument
SELECT COALESCE(phone, email, 'no contact') AS best_contact
FROM customers;

-- NULLIF: returns NULL if both arguments are equal, otherwise first argument
-- Classic use: prevent division by zero
SELECT revenue / NULLIF(order_count, 0) AS aov FROM order_summary;
-- If order_count = 0 → NULLIF returns NULL → division returns NULL (not error)

-- [PostgreSQL Specific] IS DISTINCT FROM / IS NOT DISTINCT FROM: NULL-safe comparison
UPDATE products
SET price = 0
WHERE new_price IS NOT DISTINCT FROM old_price;  -- includes NULL = NULL case
```

---

## 11. Interview Questions

**Q1: What does `NULL = NULL` evaluate to in SQL, and why?**
`UNKNOWN`. `NULL` represents an unknown value. Comparing two unknown values cannot produce a definitive answer — we don't know whether the two unknowns are the same or different. SQL's three-valued logic (TRUE, FALSE, UNKNOWN) requires using `IS NULL` or `IS NOT NULL` to test for null presence, not equality operators.

**Q2: Explain the NOT IN + NULL trap.**
`NOT IN (subquery)` expands to a series of `<>` comparisons ANDed together. If the subquery returns even one `NULL`, the expression becomes `value <> NULL`, which evaluates to `UNKNOWN`. Since `WHERE` only passes `TRUE`, every row is rejected — the query silently returns zero rows. Fix by using `NOT EXISTS` (which tests for row existence, not value equality) or by adding `WHERE column IS NOT NULL` inside the subquery.

**Q3: How does NULL behave in AVG()?**
`AVG` ignores NULL values entirely and divides the sum by the count of non-NULL values only. This means if 3 out of 10 rows have NULL amounts, `AVG(amount)` divides the sum by 7, not 10. This can inflate the average if NULLs are meaningful zeros. Use `AVG(COALESCE(amount, 0))` to include zeros in the denominator when NULLs should be treated as zero.

**Q4: Can a UNIQUE constraint column contain multiple NULLs in PostgreSQL?**
Yes, by default. The SQL standard treats each `NULL` as an unknown distinct value, so multiple NULLs are permitted in a `UNIQUE` column. PostgreSQL 15+ introduced `UNIQUE NULLS NOT DISTINCT` to change this behavior and treat NULLs as equal for uniqueness purposes — useful for nullable business keys where only one "unknown" should be allowed.

---

## 12. Further Reading
- [PostgreSQL 18 Documentation: NULL Values](https://www.postgresql.org/docs/18/functions-comparison.html)
- [PostgreSQL 18 Documentation: COALESCE and NULLIF](https://www.postgresql.org/docs/18/functions-conditional.html)
