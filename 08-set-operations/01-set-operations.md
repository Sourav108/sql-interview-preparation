# Module 08: Set Operations

## 1. Concept

Set operations combine the result sets of two or more `SELECT` queries. Both queries must have:
- The same number of columns.
- Compatible (coercible) data types in corresponding columns.
- Column names come from the **first** query.

| Operation | Returns | Duplicates |
| :--- | :--- | :--- |
| `UNION` | All rows from both result sets | **Removed** (implicit DISTINCT sort) |
| `UNION ALL` | All rows from both result sets | **Kept** (simple append, fastest) |
| `INTERSECT` | Only rows that appear in **both** result sets | Removed |
| `EXCEPT` | Rows in the first set **not** in the second | Removed |

---

## 2. UNION vs UNION ALL

```sql
-- UNION: deduplicates — expensive (requires sort/hash to find duplicates)
SELECT email FROM customers WHERE first_name = 'Alice'
UNION
SELECT email FROM customers WHERE last_name = 'Chen';
-- Returns 1 row if Alice Chen exists (same email deduped)

-- UNION ALL: no deduplication — use when you know rows are distinct or duplicates are wanted
SELECT 'delivered' AS source, id, total FROM orders WHERE status = 'DELIVERED'
UNION ALL
SELECT 'shipped',              id, total FROM orders WHERE status = 'SHIPPED';
-- Returns all delivered + all shipped with a source label — fast, no sort
```

**Performance rule**: Always prefer `UNION ALL` unless you explicitly need deduplication. `UNION` forces a sort or hash operation proportional to the total row count.

---

## 3. INTERSECT — Common Rows

```sql
-- Customers who placed an order in BOTH 2025 AND 2026
SELECT customer_id FROM orders WHERE placed_at >= '2025-01-01' AND placed_at < '2026-01-01'
INTERSECT
SELECT customer_id FROM orders WHERE placed_at >= '2026-01-01' AND placed_at < '2027-01-01';
-- Equivalent: customers with orders in both years (Alice Chen from seed data)
```

---

## 4. EXCEPT — Set Difference

```sql
-- Products that were sold in 2025 but NOT sold in 2026
SELECT DISTINCT product_id FROM order_items oi
JOIN orders o ON o.id = oi.order_id
WHERE o.placed_at >= '2025-01-01' AND o.placed_at < '2026-01-01'

EXCEPT

SELECT DISTINCT product_id FROM order_items oi
JOIN orders o ON o.id = oi.order_id
WHERE o.placed_at >= '2026-01-01' AND o.placed_at < '2027-01-01';
```

---

## 5. Set Operations vs Joins

| Use Case | Set Operation | Equivalent Join |
| :--- | :--- | :--- |
| Rows in A and not in B | `EXCEPT` | `LEFT JOIN ... WHERE B.id IS NULL` (anti-join) |
| Rows in both A and B | `INTERSECT` | `INNER JOIN` (if using PK columns) |
| All rows from A and B | `UNION ALL` | `FULL OUTER JOIN` (not identical — different column structure) |

---

## 6. Interview Questions

**Q1: What is the difference between UNION and UNION ALL?**
`UNION` appends the two result sets and removes duplicates using an implicit sort or hash-based deduplication — it requires additional CPU and memory. `UNION ALL` simply appends both result sets without any deduplication, making it significantly faster. Use `UNION ALL` whenever you know the results are already distinct or when you explicitly want all rows (including duplicates), and reserve `UNION` for when deduplication is required.

**Q2: When would EXCEPT be more readable than a LEFT JOIN anti-join?**
When comparing two logically parallel result sets that are not related by a foreign key. For example, comparing two email lists, two sets of product IDs from different reporting periods, or two sets of customer segments. EXCEPT reads naturally as "what is in set A that is not in set B." The LEFT JOIN anti-join pattern requires more syntactic noise. Both produce the same result; the choice is about readability and query structure.
