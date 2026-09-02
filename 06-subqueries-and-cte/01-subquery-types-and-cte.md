# 01. Subquery Types

## 1. Scalar Subquery

Returns exactly **one row, one column**. Can appear anywhere a single value is expected.

```sql
-- In SELECT: enrich each order with the customer's average order value
SELECT
    o.id,
    o.total,
    (SELECT ROUND(AVG(o2.total)::NUMERIC, 2)
     FROM orders o2
     WHERE o2.customer_id = o.customer_id
       AND o2.status <> 'CANCELLED') AS customer_avg_order
FROM orders o
WHERE o.status = 'DELIVERED';
```

**Trap**: If a scalar subquery returns more than one row, PostgreSQL raises:
`ERROR: more than one row returned by a subquery used as an expression`
Always ensure scalar subqueries have a deterministic single-row guarantee (`LIMIT 1`, aggregate function, or unique join).

---

## 2. Correlated Subquery

A subquery that **references a column from the outer query**. Re-executed once per outer row.

```sql
-- Orders where total exceeds the customer's own average
SELECT o.id, o.customer_id, o.total
FROM orders o
WHERE o.total > (
    SELECT AVG(o2.total)
    FROM orders o2
    WHERE o2.customer_id = o.customer_id  -- references outer 'o'
);
```

**Performance**: Correlated subqueries can be O(N) — evaluated once per outer row. PostgreSQL often converts them to equivalent `JOIN` or window-function plans via query unnesting. Run `EXPLAIN` to verify the plan.

---

## 3. Derived Table (Inline View)

A subquery in the `FROM` clause, acting as a temporary table.

```sql
-- Customers who have placed more than 1 order, with their total count
SELECT c.email, order_stats.order_count, order_stats.total_spent
FROM customers c
JOIN (
    SELECT
        customer_id,
        COUNT(*)   AS order_count,
        SUM(total) AS total_spent
    FROM orders
    WHERE status <> 'CANCELLED'
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) order_stats ON order_stats.customer_id = c.id
ORDER BY order_stats.total_spent DESC;
```

Derived tables must be aliased. They are **not** materialized unless wrapped in a CTE with `MATERIALIZED`.

---

## 4. EXISTS vs IN vs JOIN

```sql
-- All three find customers with at least one DELIVERED order:

-- A: INNER JOIN + DISTINCT (avoid — row multiplication + extra sort)
SELECT DISTINCT c.email FROM customers c
JOIN orders o ON o.customer_id = c.id AND o.status = 'DELIVERED';

-- B: IN subquery (OK when subquery column is NOT NULL)
SELECT c.email FROM customers c
WHERE c.id IN (SELECT customer_id FROM orders WHERE status = 'DELIVERED');

-- C: EXISTS (recommended — stops at first match, NULL-safe, clear intent)
SELECT c.email FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.id AND o.status = 'DELIVERED'
);
```

PostgreSQL generates equivalent **Hash Semi-Join** plans for B and C in most cases.

---

## 5. CTEs — WITH Clause

CTEs name a subquery so it can be referenced multiple times and improve readability.

```sql
-- Multi-step reporting: top customers by revenue with their payment completion rate
WITH
delivered_orders AS (
    SELECT customer_id, SUM(total) AS revenue
    FROM orders
    WHERE status = 'DELIVERED'
    GROUP BY customer_id
),
payment_stats AS (
    SELECT o.customer_id,
           COUNT(*) FILTER (WHERE p.status = 'COMPLETED') * 100.0
           / NULLIF(COUNT(*), 0) AS payment_success_pct
    FROM orders o
    JOIN payments p ON p.order_id = o.id
    GROUP BY o.customer_id
)
SELECT
    c.email,
    d.revenue,
    ROUND(ps.payment_success_pct::NUMERIC, 1) AS payment_success_pct
FROM customers c
JOIN delivered_orders d  ON d.customer_id = c.id
JOIN payment_stats ps    ON ps.customer_id = c.id
ORDER BY d.revenue DESC
LIMIT 5;
```

> **[PostgreSQL Specific] — CTE Materialization**:
> - By default in PostgreSQL 12+, CTEs are **not** materialized unless the planner determines it's beneficial (or contains volatile functions, `RETURNING`, etc.).
> - Force materialization: `WITH cte AS MATERIALIZED (...)` — creates a physical temp result.
> - Prevent materialization: `WITH cte AS NOT MATERIALIZED (...)` — inlines the CTE as a subquery.
> - Pre-PostgreSQL 12: all CTEs were optimization fences (always materialized).

---

## 6. Recursive CTEs

Recursive CTEs traverse hierarchical or graph data where depth is unknown at query time.

```sql
-- Traverse the employee org chart from a given manager
WITH RECURSIVE org_tree AS (
    -- Anchor: the root (or chosen starting employee)
    SELECT id, first_name, manager_id, 0 AS depth, ARRAY[id] AS path
    FROM employees
    WHERE manager_id IS NULL   -- top-level: no manager = CEO

    UNION ALL

    -- Recursive member: join children to their parents
    SELECT e.id, e.first_name, e.manager_id, ot.depth + 1, ot.path || e.id
    FROM employees e
    JOIN org_tree ot ON e.manager_id = ot.id
    WHERE NOT e.id = ANY(ot.path)  -- [PostgreSQL Specific] cycle detection
)
SELECT
    REPEAT('  ', depth) || first_name AS org_chart,
    depth
FROM org_tree
ORDER BY path;
```

```
org_chart        depth
Priya            0
  Rohan          1
    Sneha         2
    Vikram        2
  Arjun          1
    Meera         2
```

**Recursive CTE Anatomy**:
```
WITH RECURSIVE cte AS (
    [anchor member]       ← non-recursive base case
    UNION ALL
    [recursive member]    ← references cte itself; adds rows each iteration
)
SELECT * FROM cte;
-- Terminates when the recursive member produces no new rows
```

**Common uses**: Org charts, category trees, bill of materials, graph path traversal, date series generation.

---

## 7. Interview Questions

**Q1: What is the difference between a CTE and a derived table (subquery in FROM)?**
Both define a named result set scoped to the query. The key differences: (1) A CTE can be referenced **multiple times** in the same query without re-computation (when materialized); a derived table must be repeated. (2) CTEs support **recursive** queries; derived tables do not. (3) CTEs improve readability by naming intermediate steps. (4) In PostgreSQL 12+, a CTE is not necessarily an optimization fence — the planner may inline it unless explicitly forced with `MATERIALIZED`.

**Q2: When would a correlated subquery be preferable to a JOIN?**
Correlated subqueries are preferable when: (a) you need a **scalar value** from a related table for each row without multiplying rows (e.g., "last order date per customer"); (b) the logic is clearest as a per-row lookup; (c) the existence check pattern `EXISTS / NOT EXISTS` is more readable than an equivalent anti-join. However, if performance is critical, verify via `EXPLAIN ANALYZE` — the optimizer often converts both to the same join plan.

**Q3: How do you detect and prevent infinite recursion in a recursive CTE?**
PostgreSQL provides two mechanisms: (1) The `path` array technique — maintain an array of visited node IDs and add `WHERE NOT id = ANY(path)` in the recursive member. (2) The `CYCLE` clause (SQL:1999, PostgreSQL 14+): `SEARCH DEPTH FIRST BY id SET is_cycle CYCLE id SET is_cycled USING path` automatically detects cycles. Additionally, PostgreSQL enforces a `recursive_worktable_factor` and terminates after a configurable maximum recursion depth.

---

## 8. Further Reading
- [PostgreSQL 18 Documentation: WITH Queries (CTEs)](https://www.postgresql.org/docs/18/queries-with.html)
- [PostgreSQL 18 Documentation: Scalar Subqueries](https://www.postgresql.org/docs/18/sql-expressions.html#SQL-SYNTAX-SCALAR-SUBQUERIES)
