# 02. Join Predicates, ON vs WHERE, and the Outer-Join Filter Trap

## 1. Problem

The most common join bug in production code: a developer writes a `LEFT JOIN` to preserve unmatched rows, then adds a `WHERE` clause that silently eliminates all those `NULL`-extended rows — converting the outer join into an inner join without any error message.

---

## 2. Concept: `ON` vs `WHERE` in Joins

| Clause | Logical Step | Effect on Outer Join |
| :--- | :--- | :--- |
| `ON` | Step 2–3: Join construction | Part of the join predicate; determines which rows are matched. `NULL`-extended rows for unmatched left-side rows are **still produced**. |
| `WHERE` | Step 4: Post-join row filter | Applied *after* the joined row set is constructed. Eliminates rows that do not satisfy the predicate — **including** the `NULL`-extended rows from outer joins. |

---

## 3. The Outer-Join Filter Trap

### 3.1 The Bug

```sql
-- Goal: All customers + their DELIVERED orders (show NULL for customers with no DELIVERED orders)
-- ❌ WRONG — WHERE kills the NULL-extended rows
SELECT c.email, o.id AS order_id, o.status
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.status = 'DELIVERED';    -- This filters out NULLs → becomes INNER JOIN!
-- Result: Only customers who have at least one DELIVERED order (8 rows)
-- Missing: Leo, Henry, James, Karen (no orders at all)
-- Missing: Bob (has orders but only CANCELLED/DELIVERED — actually present here)
-- Missing: Carol, Grace (only PENDING orders — their NULL-extended rows are filtered out)
```

### 3.2 The Fix — Move Filter Into `ON`

```sql
-- ✅ CORRECT — Filter is part of the join condition
SELECT c.email, o.id AS order_id, o.status
FROM customers c
LEFT JOIN orders o
    ON  o.customer_id = c.id
    AND o.status = 'DELIVERED';  -- Moves filter inside the join ON clause
-- Result: All 12 customers.
-- Customers with a DELIVERED order: show the matching order row(s).
-- Customers with no DELIVERED order (or no orders): order columns are NULL.
```

### 3.3 Mental Model for ON vs WHERE

```
FROM customers c
LEFT JOIN orders o
    ON o.customer_id = c.id    ← JOIN CONSTRUCTION: match rows here
    AND o.status = 'DELIVERED' ← JOIN FILTER: applies during matching, not after
WHERE c.created_at > '2025-01-01' ← POST-JOIN FILTER: applies to ALL rows (safe here,
                                    because it filters on the left/preserved side)
```

**Rule**: Filters on the **right side** of a `LEFT JOIN` must go into the `ON` clause to preserve the outer-join semantics. Filters on the **left side** (preserved side) can safely go in `WHERE`.

---

## 4. Filtering Before vs After Joins

### 4.1 Pre-Join Filtering (Performance Benefit)

Filtering rows *before* the join reduces the size of the joined row set:

```sql
-- ✅ Filter products before joining — reduces order_items scan scope
SELECT o.id, p.name, oi.quantity
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN (
    SELECT id, name FROM products WHERE category = 'Keyboards'
) p ON p.id = oi.product_id;
-- Only joins order_items rows that match a keyboard product
```

PostgreSQL's query optimizer will often apply **predicate pushdown** automatically — but explicit pre-filtering in CTEs with `MATERIALIZED` or subqueries can be important when the optimizer's estimate is wrong.

### 4.2 Post-Join Filtering

```sql
-- Filter after the join — correct when the filter needs data from both sides
SELECT c.email, o.total
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE o.total > 10000 AND c.created_at < '2026-01-01';
```

---

## 5. Multi-Table Join Ordering

SQL join order does not affect correctness (the optimizer handles it), but it affects readability and, in rare cases, can influence plan choices:

```sql
-- Standard practice: left-to-right, most restrictive table first
SELECT c.email, o.id, p.name, oi.quantity
FROM customers c                              -- 12 rows (root anchor)
JOIN orders o     ON o.customer_id = c.id    -- 11 rows (narrows)
JOIN order_items oi ON oi.order_id = o.id   -- 18 rows (expands slightly)
JOIN products p   ON p.id = oi.product_id;  -- 8 rows (lookups)
```

---

## 6. Non-Equi Joins

Joins don't require equality — any boolean predicate works in `ON`:

```sql
-- Find customers who placed an order that exceeds their average historical order
SELECT c.email, o.id, o.total
FROM orders o
JOIN customers c ON c.id = o.customer_id
JOIN (
    SELECT customer_id, AVG(total) AS avg_total
    FROM orders
    WHERE status = 'DELIVERED'
    GROUP BY customer_id
) avg_orders
    ON  avg_orders.customer_id = o.customer_id
    AND o.total > avg_orders.avg_total;  -- Non-equi join predicate
```

```sql
-- [PostgreSQL Specific]: Range overlap anti-join using exclusion constraint approach
-- Verify no two bookings for the same room overlap in date range
SELECT a.id, b.id
FROM bookings a
JOIN bookings b
    ON  a.room_id = b.room_id
    AND a.id      < b.id                    -- Avoid self-match and duplicates
    AND a.check_in  < b.check_out           -- Non-equi: date range overlap test
    AND b.check_in  < a.check_out;
```

---

## 7. Interview Questions

**Q1: Why does adding a `WHERE` clause on the right-table column after a `LEFT JOIN` effectively convert it to an `INNER JOIN`?**
The `LEFT JOIN` produces `NULL`-extended rows for unmatched left-side rows — the right-table columns for those rows are `NULL`. When a `WHERE` clause tests a right-table column (e.g., `WHERE status = 'DELIVERED'`), it evaluates `NULL = 'DELIVERED'`, which is `UNKNOWN` in 3-valued logic. `WHERE` only passes rows where the predicate is `TRUE`, so all `NULL`-extended rows are eliminated. The fix is to move the filter into the `ON` clause where it participates in the join construction rather than post-join row elimination.

**Q2: A query runs 10× slower after you added a filter on a joined table. What might be happening?**
Several possibilities: (1) The filter is on the right side of a `LEFT JOIN` in a `WHERE` clause, forcing the engine to process the full outer join then eliminate rows, rather than using the predicate during join construction. (2) The filter column lacks an index, forcing a sequential scan on the joined table. (3) The filter is non-sargable (e.g., `WHERE YEAR(date_col) = 2026`), preventing index use. The diagnostic approach: run `EXPLAIN (ANALYZE, BUFFERS)` before and after the filter addition and compare scan types and actual row counts.

**Q3: What is a non-equi join? Give a production example.**
A non-equi join uses a predicate other than equality in the `ON` clause — such as `<`, `>`, `BETWEEN`, or `OVERLAPS`. Example: a salary grade lookup where `ON emp.salary BETWEEN grade.min_salary AND grade.max_salary`; or a temporal booking overlap check where `ON a.check_in < b.check_out AND b.check_in < a.check_out`. Non-equi joins typically require Nested Loop or Merge Join execution (Hash Join only supports equi-join predicates).

---

## 8. Further Reading
- [PostgreSQL 18 Documentation: JOIN conditions](https://www.postgresql.org/docs/18/queries-table-expressions.html#QUERIES-JOIN)
