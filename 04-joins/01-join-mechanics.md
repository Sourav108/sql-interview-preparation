# 01. Join Mechanics: Every Join Type Explained

## 1. Problem

Joins are the mechanism by which relational data is reassembled into meaningful results. Every incorrect join produces either **missing rows** (wrong join type) or **row multiplication** (unconstrained join predicate). Knowing the mechanics — not just the syntax — is what separates strong candidates from weak ones.

---

## 2. The Conceptual Execution Model

The database evaluates joins as:
1. **Cartesian product** of the participating tables: every row from the left paired with every row from the right.
2. **Filter** the Cartesian product using the `ON` predicate to keep only matching pairs.
3. For **outer joins**: restore eliminated rows from one or both sides, filling unmatched columns with `NULL`.

---

## 3. Join Types in Detail

### 3.1 INNER JOIN

Returns only rows where the `ON` predicate is `TRUE` in **both tables**. Unmatched rows from either side are dropped.

```sql
-- [Standard SQL]
-- Customers who have placed at least one order
SELECT c.first_name, c.last_name, o.id AS order_id, o.total
FROM customers c
INNER JOIN orders o ON o.customer_id = c.id;
```

```
customers (12 rows) INNER JOIN orders (11 rows, 8 distinct customers)
→ Result: 11 rows (one per order row; customers with no orders are dropped)
```

**Key property**: An `INNER JOIN` is symmetric — `A INNER JOIN B` and `B INNER JOIN A` produce identical row sets (column order differs).

---

### 3.2 LEFT OUTER JOIN

Returns **all rows from the left table**. For rows that have no match in the right table, right-side columns are filled with `NULL`.

```sql
-- All customers, including those who have never ordered
SELECT c.first_name, c.last_name, o.id AS order_id, o.total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id;
```

```
customers (12 rows) LEFT JOIN orders (11 rows)
→ Customers with orders:     8 customers × their orders  = 11 rows (matched)
→ Customers without orders:  4 customers                 = 4 rows  (NULL-extended)
→ Total result: 15 rows
```

**Null extension**: For Leo Santos (no orders), the result row contains:
```
first_name='Leo', last_name='Santos', order_id=NULL, total=NULL
```

---

### 3.3 RIGHT OUTER JOIN

Mirror of `LEFT JOIN`: returns all rows from the **right table**, with `NULL` for unmatched left columns. In practice, `RIGHT JOIN` is rarely written — it is always rewritable as a `LEFT JOIN` with tables swapped.

```sql
-- Equivalent queries:
SELECT c.id, o.id FROM customers c RIGHT JOIN orders o ON o.customer_id = c.id;
SELECT o.id, c.id FROM orders o LEFT  JOIN customers c ON c.id = o.customer_id;
```

---

### 3.4 FULL OUTER JOIN

Returns **all rows from both tables**. Unmatched rows from each side get `NULL` for the opposing side's columns.

```sql
-- All customers and all orders, even if the relationship is broken on either side
SELECT c.first_name, o.id AS order_id
FROM customers c
FULL OUTER JOIN orders o ON o.customer_id = c.id;
```

**Primary use case**: Detecting mismatches between two data sources during reconciliation or migration audits.

---

### 3.5 CROSS JOIN (Cartesian Product)

Every row from the left paired with every row from the right. No `ON` predicate. Result: `M × N` rows.

```sql
-- Intentional: generate all possible (size, color) combinations for a product matrix
SELECT s.size_name, c.color_name
FROM sizes s
CROSS JOIN colors c;
```

**Accidental Cartesian product** (dangerous): Forgetting to write the join predicate when listing multiple tables in `FROM`:
```sql
-- ❌ ACCIDENTAL — no join condition between orders and products
SELECT o.id, p.name
FROM orders o, products p;  -- 11 orders × 8 products = 88 rows!
```

Always use explicit `JOIN ... ON` syntax to prevent this.

---

### 3.6 SELF JOIN

A table joined to itself. Requires aliases to distinguish the two roles.

```sql
-- Employees with their manager's name
-- employees: (id, first_name, manager_id → employees.id)
SELECT
    e.first_name                             AS employee,
    m.first_name                             AS manager
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id;
-- LEFT JOIN: includes employees with no manager (CEO/root node)
```

---

## 4. The Row Multiplication Problem

**The most important performance and correctness trap in joins.**

When you join on a 1:N relationship, each "1" side row is duplicated once for every matching "N" side row.

```sql
-- WRONG: Trying to get the total shipping cost + number of items per order
-- orders.shipping_cost is on the "1" side; order_items is the "N" side
SELECT
    o.id,
    o.shipping_cost,
    COUNT(oi.product_id)        AS item_count,
    SUM(o.shipping_cost)        AS WRONG_total_shipping  -- multiplied N times!
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id, o.shipping_cost;

-- For Order 9 (Frank): 3 order_items rows
-- SUM(o.shipping_cost) = 0.00 + 0.00 + 0.00 = 0.00 (happens to be correct)
-- But for Order 1 (Alice): SUM(shipping_cost) sums the same 0.00 twice
-- The bug surfaces when shipping_cost is non-zero AND order has multiple items!

-- ✅ CORRECT: Aggregate the child side first, then join
SELECT
    o.id,
    o.shipping_cost,
    oi_agg.item_count,
    oi_agg.items_subtotal
FROM orders o
JOIN (
    SELECT
        order_id,
        COUNT(*)                       AS item_count,
        SUM(quantity * unit_price)     AS items_subtotal
    FROM order_items
    GROUP BY order_id
) oi_agg ON oi_agg.order_id = o.id;
```

**Rule**: When joining on a 1:N relationship and aggregating a column from the "1" side, **always aggregate the N side first** (in a subquery or CTE) before joining.

---

## 5. M:N Join Multiplication

When joining through a junction table, you get one result row per combination:

```sql
-- Customer → Orders → Order_Items: three-level join
-- Each customer row multiplied by number of orders, which is multiplied by number of items
SELECT c.first_name, o.id, p.name, oi.quantity
FROM customers c
JOIN orders o ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id;
-- Alice (3 orders, 4 items total) → 4 result rows for Alice
```

**Predicting join output size**:
- `customers (12) INNER JOIN orders (11)` → 11 rows (one per order)
- Adding `JOIN order_items (18)` → 18 rows (one per item)
- Adding `JOIN products (8)` → still 18 rows (each item has exactly 1 product)

---

## 6. Interview Questions

**Q1: What is the difference between `INNER JOIN` and `LEFT JOIN`?**
`INNER JOIN` returns only rows that have a matching record in both tables. Unmatched rows from either side are dropped. `LEFT JOIN` returns all rows from the left table; unmatched rows from the right table produce `NULL` for the right-side columns. Use `INNER JOIN` when you are certain a relationship always exists and missing matches represent data errors. Use `LEFT JOIN` when you want to preserve all left-side rows regardless of whether a matching right-side record exists.

**Q2: You have a query joining `orders` to `order_items` and you find your `SUM(shipping_cost)` is wrong. What happened and how do you fix it?**
The `shipping_cost` column lives on `orders` (the "1" side). Joining to `order_items` (the "N" side) replicates each order row once per line item. A `SUM` on `shipping_cost` then sums the same value multiple times. The fix is to aggregate `order_items` into a subquery first (grouping by `order_id`), then join the aggregated result back to `orders`. This preserves one row per order before any aggregation occurs.

**Q3: What does a `CROSS JOIN` produce and when would you use it intentionally?**
A `CROSS JOIN` produces the Cartesian product of two tables — every row from the left paired with every row from the right, resulting in `M × N` rows. Intentional uses include: generating all combinations of attributes (size × color product variants), filling sparse matrix tables, and generating test data. Accidental Cartesian products occur when a `JOIN` predicate is accidentally omitted — use explicit `JOIN ... ON` syntax to prevent this.

**Q4: How does a `FULL OUTER JOIN` differ from a `UNION` of `LEFT JOIN` and `RIGHT JOIN`?**
Both produce a similar row set, but `FULL OUTER JOIN` is cleaner, evaluated in a single pass, and less error-prone. A `UNION` of `LEFT JOIN UNION RIGHT JOIN` can double-count matched rows if not written carefully. The optimizer can also apply `FULL OUTER JOIN` more efficiently in certain execution plans (e.g., using a Hash Full Join node).

---

## 7. Further Reading
- [PostgreSQL 18 Documentation: Joins Between Tables](https://www.postgresql.org/docs/18/tutorial-join.html)
- [PostgreSQL 18 Documentation: FROM Clause](https://www.postgresql.org/docs/18/sql-select.html#SQL-FROM)
- [Use The Index, Luke: Joins](https://use-the-index-luke.com/sql/join)
