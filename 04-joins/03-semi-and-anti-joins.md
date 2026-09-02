# 03. Semi-Joins and Anti-Joins: EXISTS and NOT EXISTS

## 1. Problem

Two of the most common interview question patterns are:
- *"Find customers who have placed at least one order"* → **Semi-join** (existence check)
- *"Find customers who have never placed an order"* → **Anti-join** (non-existence check)

These are not just about choosing between `JOIN`, `IN`, and `EXISTS` — the choice has correctness, NULL-safety, and performance implications.

---

## 2. Semi-Join: Checking Existence Without Row Multiplication

A semi-join returns left-side rows for which **at least one matching** right-side row exists. Critically: it does **not** multiply left rows.

### 2.1 Three Ways to Write a Semi-Join

```sql
-- Goal: Find all customers who have placed at least one order

-- Approach A: INNER JOIN + DISTINCT (❌ expensive and fragile)
SELECT DISTINCT c.id, c.email
FROM customers c
JOIN orders o ON o.customer_id = c.id;
-- Forces a DISTINCT sort/hash across the full join output. Masks a row-multiplication bug.

-- Approach B: IN subquery
SELECT c.id, c.email
FROM customers c
WHERE c.id IN (SELECT o.customer_id FROM orders o);
-- NULL TRAP: If orders.customer_id contained any NULL, this is still safe here
-- because we're filtering c.id (a NOT NULL PK). But see NOT IN trap below.

-- Approach C: EXISTS ✅ Recommended
SELECT c.id, c.email
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.id
);
-- Correlated subquery: evaluated once per customer row.
-- Stops at first match — no row multiplication.
-- Semantically clear: "there exists at least one order for this customer."
```

### 2.2 How the PostgreSQL Optimizer Handles Semi-Joins

PostgreSQL's optimizer recognizes both `IN (subquery)` and `EXISTS` patterns and can convert them to the same **Hash Semi-Join** or **Nested Loop Semi-Join** plan. The difference in written form is primarily about:
- **Readability**: `EXISTS` is more expressive of intent.
- **NULL safety**: `EXISTS` is always NULL-safe; `IN` has the `NOT IN` NULL trap.
- **Optimizer flexibility**: Both are equivalent in most cases for equi-join predicates.

```
-- Execution plan PostgreSQL uses for EXISTS (semi-join):
Hash Semi Join
  Hash Cond: (c.id = o.customer_id)
  ->  Seq Scan on customers
  ->  Hash
        ->  Seq Scan on orders
-- Stops after first hash bucket match per customer — no duplicates, no DISTINCT needed
```

---

## 3. Anti-Join: Checking Non-Existence

An anti-join returns left-side rows for which **no matching** right-side row exists.

### 3.1 Three Ways to Write an Anti-Join

```sql
-- Goal: Find all customers who have NEVER placed an order

-- Approach A: NOT IN subquery ❌ DANGEROUS
SELECT c.id, c.email
FROM customers c
WHERE c.id NOT IN (SELECT o.customer_id FROM orders o);
-- CRITICAL TRAP: If any orders.customer_id is NULL:
--   c.id NOT IN (..., NULL) evaluates to UNKNOWN for every row
--   Result: ZERO ROWS returned — a silent correctness failure.
-- In our schema, customer_id is NOT NULL — but this is a fragile assumption.
-- If a future migration makes it nullable, this query silently breaks.

-- Approach B: LEFT JOIN + WHERE NULL ✅ Reliable
SELECT c.id, c.email
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;
-- NULL-safe: rows with no matching order produce o.id = NULL
-- Filter keeps only those NULL rows.

-- Approach C: NOT EXISTS ✅ Recommended (clearest intent + NULL-safe)
SELECT c.id, c.email
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.id
);
-- Evaluates to TRUE if no matching rows exist — NULL-safe by design.
-- PostgreSQL executes as Hash Anti-Join: efficient and explicit.
```

**Using our seed data:**
```sql
SELECT c.first_name, c.last_name FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```
Expected result:
| first_name | last_name |
| :--- | :--- |
| Henry | Park |
| James | Wu |
| Karen | Hall |
| Leo | Santos |

---

## 4. The NOT IN + NULL Trap — Detailed

This is one of the most common interview trap questions:

```sql
-- Setup: What if a cancelled order had a NULL customer_id?
-- (Hypothetical - demonstrates the trap)
-- INSERT INTO orders (customer_id, ...) VALUES (NULL, ...);  -- orphaned order

SELECT c.id FROM customers c
WHERE c.id NOT IN (
    SELECT customer_id FROM orders  -- If this returns any NULL: all rows disappear
);

-- The logic:
-- NOT IN evaluates as: c.id <> 1 AND c.id <> 2 AND ... AND c.id <> NULL
-- c.id <> NULL → UNKNOWN (in 3-valued logic)
-- FALSE AND UNKNOWN → FALSE
-- TRUE AND UNKNOWN → UNKNOWN  ← fails the WHERE test
-- Result: No row passes the filter → empty result set

-- ✅ Safe NOT IN with explicit NULL guard:
WHERE c.id NOT IN (
    SELECT customer_id FROM orders WHERE customer_id IS NOT NULL
)
-- Or simply: use NOT EXISTS instead
```

---

## 5. Semi-Join vs Anti-Join Performance

Both `EXISTS`/`NOT EXISTS` and `LEFT JOIN ... WHERE NULL` produce equivalent execution plans in PostgreSQL — the optimizer converts them to **Hash Semi-Join** and **Hash Anti-Join** nodes respectively.

```sql
-- Compare plans for these equivalent anti-join queries:
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.id FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

EXPLAIN (ANALYZE, BUFFERS)
SELECT c.id FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;
-- Both should show: Hash Anti Join
```

---

## 6. Summary: Choosing the Right Pattern

| Goal | Recommended Pattern | Avoid |
| :--- | :--- | :--- |
| Rows where match exists (semi-join) | `WHERE EXISTS (SELECT 1 FROM ...)` | `INNER JOIN + DISTINCT` |
| Rows where no match exists (anti-join) | `WHERE NOT EXISTS (SELECT 1 FROM ...)` | `NOT IN (SELECT nullable_col ...)` |
| Count/aggregate over matching children | `INNER JOIN` then `GROUP BY` | Semi-join (can't aggregate child data) |
| Preserve left rows with optional match | `LEFT JOIN` | Subquery that might return multiple rows |

---

## 7. Interview Questions

**Q1: What is the difference between an INNER JOIN and EXISTS for checking whether a customer has orders?**
Both find customers who have at least one order. The critical difference: `INNER JOIN` multiplies customer rows — if a customer has 5 orders, the customer appears 5 times. You need `DISTINCT` to collapse them, adding an expensive sort step. `EXISTS` (semi-join) stops after the first matching row is found and returns the customer row exactly once — no multiplication, no `DISTINCT` needed. The optimizer generates a Hash Semi-Join plan for both `EXISTS` and `IN (subquery)` patterns.

**Q2: You wrote `WHERE id NOT IN (SELECT customer_id FROM orders)` and it returns zero rows even though many customers never ordered. What happened?**
The `orders.customer_id` column contains at least one `NULL`. In 3-valued logic, `id NOT IN (..., NULL)` evaluates to `id <> NULL`, which is `UNKNOWN`. Since `WHERE` only passes `TRUE`, all rows are eliminated. Fix: use `NOT EXISTS (SELECT 1 FROM orders WHERE customer_id = c.id)` or add `WHERE customer_id IS NOT NULL` inside the subquery.

**Q3: A colleague argues that `NOT IN` is simpler than `NOT EXISTS`. How do you respond?**
`NOT IN` is only safe when the subquery column has a strict `NOT NULL` database constraint. Without that guarantee, any future `NULL` inserted into the column silently breaks the query. `NOT EXISTS` is NULL-safe by design and semantically clear: "there exists no matching row." For production SQL, `NOT EXISTS` is the safer default. The optimizer produces equivalent plans for both patterns when the column is provably `NOT NULL`.

---

## 8. Further Reading
- [PostgreSQL 18 Documentation: Subquery Expressions](https://www.postgresql.org/docs/18/functions-subquery.html)
- [Use The Index, Luke: Subqueries and Semi-Joins](https://use-the-index-luke.com/sql/where-clause/obfuscation/exists)
