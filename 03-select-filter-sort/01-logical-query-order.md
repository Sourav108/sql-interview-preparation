# 01. The Logical SQL Query Processing Order

## 1. Problem

Developers write SQL in `SELECT ... FROM ... WHERE ...` order, which mirrors English but does **not** reflect how the database logically evaluates the query. This disconnect causes real bugs:

- `WHERE` can't see `SELECT` aliases — produces `ERROR: column "alias" does not exist`.
- `HAVING` vs `WHERE` confusion leads to filtering at the wrong stage.
- Using aggregate functions in `WHERE` produces `ERROR: aggregate functions not allowed in WHERE`.

Understanding the logical processing order fixes all of these.

---

## 2. Concept: The 9-Step Logical Order

SQL is evaluated in this logical sequence, regardless of how you write it:

```
Step 1: FROM        ← Identify all source tables
Step 2: ON          ← Apply JOIN predicates (part of JOIN evaluation)
Step 3: JOIN        ← Produce the joined row set (INNER, LEFT, etc.)
Step 4: WHERE       ← Filter individual rows (before grouping)
Step 5: GROUP BY    ← Collapse rows into aggregate buckets
Step 6: HAVING      ← Filter aggregate buckets (after grouping)
Step 7: SELECT      ← Evaluate expressions, compute aliases, projections
Step 8: DISTINCT    ← Eliminate duplicate result rows
Step 9: ORDER BY    ← Sort the final output
Step 10: LIMIT/OFFSET ← Paginate (applied last)
```

---

## 3. Mental Model

```
RAW TABLES (all rows)
      │
      │  Step 1–3: FROM / JOIN
      ▼
JOINED ROW SET (all combinations matching join predicates)
      │
      │  Step 4: WHERE
      ▼
FILTERED ROWS (individual row predicates applied)
      │
      │  Step 5: GROUP BY
      ▼
GROUPED BUCKETS (rows collapsed into groups)
      │
      │  Step 6: HAVING
      ▼
FILTERED GROUPS (aggregate predicates applied)
      │
      │  Step 7: SELECT
      ▼
PROJECTED RESULT (expressions evaluated, aliases defined)
      │
      │  Step 8: DISTINCT (if present)
      ▼
DEDUPLICATED RESULT
      │
      │  Step 9: ORDER BY
      ▼
SORTED RESULT
      │
      │  Step 10: LIMIT / OFFSET
      ▼
FINAL OUTPUT
```

---

## 4. Schema

```sql
-- Using the e-commerce schema from Module 02
-- Ensure these tables exist before running examples:
-- customers, orders, order_items, products
```

---

## 5. Deep Examples

### 5.1 Why `WHERE` Cannot Reference a `SELECT` Alias

```sql
-- ❌ This FAILS — alias 'total_revenue' is not visible in WHERE
SELECT customer_id, SUM(total) AS total_revenue
FROM orders
WHERE total_revenue > 5000  -- ERROR: column "total_revenue" does not exist
GROUP BY customer_id;

-- ✅ Use HAVING — it runs AFTER SELECT aliases are computed
-- But HAVING runs after GROUP BY, not after SELECT aliases in most engines
-- The correct approach: use the expression directly in HAVING
SELECT customer_id, SUM(total) AS total_revenue
FROM orders
GROUP BY customer_id
HAVING SUM(total) > 5000;  -- Repeat the expression, not the alias

-- [PostgreSQL Specific]: PostgreSQL allows ORDER BY to reference SELECT aliases
-- because ORDER BY runs after SELECT (Step 9). HAVING does NOT allow this.
SELECT customer_id, SUM(total) AS total_revenue
FROM orders
GROUP BY customer_id
HAVING SUM(total) > 5000
ORDER BY total_revenue DESC;  -- ✅ Alias works here in PostgreSQL
```

### 5.2 Why Aggregate Functions Fail in `WHERE`

```sql
-- ❌ Aggregates run in Step 7 (SELECT) — WHERE is Step 4
SELECT customer_id FROM orders
WHERE SUM(total) > 5000;  -- ERROR: aggregate functions not allowed in WHERE

-- ✅ Correct: use HAVING (Step 6) for post-aggregation filters
SELECT customer_id
FROM orders
GROUP BY customer_id
HAVING SUM(total) > 5000;
```

### 5.3 JOIN Evaluation Before WHERE

```sql
-- Step 3: All matching rows from JOIN are produced
-- Step 4: WHERE then filters this joined set

SELECT c.first_name, o.id AS order_id, o.total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.status = 'DELIVERED';

-- ⚠️ TRAP: The WHERE clause converts the LEFT JOIN into an INNER JOIN!
-- Customers with no orders (o.id IS NULL) are filtered out by WHERE.
-- To keep customers with no orders AND only count DELIVERED ones:
SELECT c.first_name, o.id AS order_id, o.total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id AND o.status = 'DELIVERED';
-- The filter is now in the ON clause (Step 2), before row elimination.
```

---

## 6. The Canonical Correct Processing Order Table

| Step | Clause | Available Context | Classic Mistake |
| :-: | :--- | :--- | :--- |
| 1–3 | `FROM`, `JOIN` | Table columns only | Forgetting join condition → Cartesian product |
| 4 | `WHERE` | Table columns, joined columns | Using `SELECT` aliases here (not yet defined) |
| 5 | `GROUP BY` | Table columns | Referencing non-aggregated `SELECT` expressions |
| 6 | `HAVING` | Aggregate results + table columns | Using `HAVING` instead of `WHERE` for non-aggregate filters (expensive) |
| 7 | `SELECT` | All of the above + window functions | Thinking `DISTINCT` eliminates duplicates before window functions |
| 8 | `DISTINCT` | Projected result | Using `DISTINCT` to mask a join multiplication bug |
| 9 | `ORDER BY` | `SELECT` projected aliases (in PostgreSQL) | Using column position numbers (fragile, breaks on schema changes) |
| 10 | `LIMIT / OFFSET` | Final sorted result | High OFFSET causing full scans — use keyset pagination |

---

## 7. Physical Execution vs Logical Processing

**Logical processing order** is the *semantic contract* SQL makes with you: results are *as if* evaluated in this order.

**Physical execution** is what the database engine *actually does* for performance. It may:
- Push filter predicates down before joins (`predicate pushdown`).
- Use index scans rather than table scans.
- Build hash tables for `GROUP BY` instead of sorting.
- Execute `LIMIT` as early as possible via `LIMIT` pipeline optimization.

```
You write:    SELECT col FROM t WHERE id = 5 LIMIT 1
You think:    Scan all rows → filter → project → limit
Engine does:  Seek via index on id → fetch first matching tuple → stop
```

> **Logical order** defines *correctness*. **Physical order** defines *performance*. Never confuse the two.

---

## 8. Interview Questions

**Q1: Why does `WHERE total_revenue > 5000` fail when `total_revenue` is a `SELECT` alias?**
Because `WHERE` is processed in Step 4, before `SELECT` in Step 7 where aliases are defined. At the time the database evaluates `WHERE`, the alias `total_revenue` does not yet exist. The fix is to reference the underlying expression in `WHERE`, or use `HAVING` for post-aggregation filters.

**Q2: What is the difference between `WHERE` and `HAVING`?**
`WHERE` filters individual rows before grouping (Step 4). It cannot reference aggregate functions. `HAVING` filters groups after aggregation (Step 6). It can reference aggregate expressions like `SUM(total)`. For performance, prefer `WHERE` over `HAVING` whenever the filter condition does not require an aggregate — pushing the filter earlier reduces the number of rows that need to be grouped.

**Q3: How does a `WHERE` clause after a `LEFT JOIN` affect the result?**
A `WHERE` predicate on a nullable column from the right-side table effectively converts a `LEFT JOIN` into an `INNER JOIN`, because the filter discards rows where the right-side column is `NULL` (i.e., rows with no match). To filter without losing the outer-join semantics, move the condition into the `ON` clause.

**Q4: Does the physical execution order match the logical processing order?**
No. The logical processing order is a semantic specification defining what the result should be — the database engine is free to physically reorder operations as long as the result is identical. Query optimizers use cost models to decide between index seeks, hash joins, materialized CTEs, and parallel workers — all invisible to the SQL author.

---

## 9. Exercises

**Exercise 1**: Using the e-commerce schema, write a query that returns the top 3 customers by total revenue, but **only** counting COMPLETED payments, and including their customer email.

**Exercise 2**: Explain why the following query produces different results:
```sql
-- Query A
SELECT c.email FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.status = 'CANCELLED';

-- Query B
SELECT c.email FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id AND o.status = 'CANCELLED';
```

---

## 10. Solutions

**Exercise 1 Solution**:
```sql
SELECT
    c.email,
    c.first_name || ' ' || c.last_name AS customer_name,
    SUM(p.amount)                       AS total_paid
FROM customers c
JOIN orders o ON o.customer_id = c.id
JOIN payments p ON p.order_id = o.id
WHERE p.status = 'COMPLETED'
GROUP BY c.id, c.email, c.first_name, c.last_name
ORDER BY total_paid DESC
LIMIT 3;
```

**Exercise 2 Solution**:
- **Query A** returns only customers *who have at least one CANCELLED order* — the `LEFT JOIN` is converted to an inner join by the `WHERE` filter.
- **Query B** returns *all customers*. For those with cancelled orders, the order columns appear. For those without any cancelled orders (including those with no orders at all), the order columns are `NULL`. The filter is in the `ON` clause, so it participates in the join construction (Step 3), not in the post-join row elimination (Step 4).

---

## 11. Further Reading
- [PostgreSQL 18 Documentation: Queries — Select](https://www.postgresql.org/docs/18/queries-overview.html)
- [Use The Index, Luke: WHERE Clause](https://use-the-index-luke.com/sql/where-clause)
