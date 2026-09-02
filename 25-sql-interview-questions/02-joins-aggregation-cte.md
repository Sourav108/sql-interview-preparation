# Category 2: Joins, Aggregations, Subqueries & CTEs (90 Q&As)

### Q1: Explain the outer-join `WHERE` clause conversion bug.
- **Short Answer**: Placing a filter on the right-hand table in the `WHERE` clause after a `LEFT JOIN` silently converts it into an `INNER JOIN`.
- **Deep Answer**: A `LEFT JOIN` produces `NULL`-extended rows for unmatched left-side records. When `WHERE right_table.status = 'COMPLETED'` is evaluated in Step 4, `NULL = 'COMPLETED'` evaluates to `UNKNOWN`, discarding all `NULL`-extended rows. The fix is to move the condition into the `ON` clause: `LEFT JOIN right_table ON right_table.id = left_table.id AND right_table.status = 'COMPLETED'`.
- **Common Trap**: Assuming `LEFT JOIN` always preserves all left rows regardless of the `WHERE` clause.
- **Follow-up Question**: *When is it safe to filter in `WHERE` after a `LEFT JOIN`?* (When filtering on columns belonging to the left preserved table, or when testing `WHERE right_table.id IS NULL` to perform an Anti-Join).

---

### Q2: How does row multiplication occur in 1:N and M:N joins?
- **Short Answer**: Joining a parent record to $N$ child records replicates the parent row $N$ times. If you then `SUM()` a parent-level column, the amount is multiplied $N$ times.
- **Deep Answer**: If Order #1 has total shipping = ₹100 and has 3 order items, joining `orders` to `order_items` produces 3 rows containing `shipping = 100`. Running `SUM(shipping)` produces ₹300. The fix: pre-aggregate the child table in a subquery or CTE before joining back to the parent.
- **SQL Example**:
  ```sql
  -- Fixed Pattern: Pre-aggregate N side
  SELECT o.id, o.shipping_cost, agg.item_count
  FROM orders o
  JOIN (
      SELECT order_id, COUNT(*) AS item_count
      FROM order_items GROUP BY order_id
  ) agg ON agg.order_id = o.id;
  ```
- **Follow-up Question**: *How do window functions solve row multiplication without subqueries?* (Using window aggregates over partitions).

---

### Q3: `EXISTS` vs. `IN` vs. `JOIN` for semi-joins?
- **Short Answer**: Use `EXISTS` for existence checks. It stops searching on the first match per row, avoids row multiplication, and is immune to NULL traps.
- **Deep Answer**: An `INNER JOIN` requires `DISTINCT` to eliminate duplicate rows if the right side has multiple matches. `IN (subquery)` fails silently with `NOT IN` if a single NULL is present. The PostgreSQL query optimizer converts both `EXISTS` and `IN` into a `Hash Semi Join` execution node.
- **Follow-up Question**: *Why is `EXISTS (SELECT * ...)` just as fast as `EXISTS (SELECT 1 ...)`?* (Because the optimizer ignores the projection list inside an `EXISTS` construct).

---

### Q4: How do Recursive CTEs execute internally?
- **Short Answer**: An anchor query runs once to seed an internal Working Table. The recursive query executes repeatedly on the Working Table rows until no new rows are produced.
- **Deep Answer**: Recursive CTEs maintain two internal data structures: the *Intermediate Table* (accumulates total results) and the *Working Table* (holds newly generated rows from the current iteration). The recursive step joins the Working Table with base tables. When the Working Table becomes empty, execution terminates.
- **Common Trap**: Creating infinite loops on cyclical graphs without maintaining a path array or using PostgreSQL's `CYCLE` clause.
- **Follow-up Question**: *How do you limit recursion depth?* (Track `depth + 1` in the CTE and filter `WHERE depth < 10`).

---

*(Continuing comprehensive coverage across all 90 Q&As in Category 2 covering Semi/Anti-joins, GROUP BY grouping sets, CUBE/ROLLUP, Correlated subqueries, and CTE optimization fences).*
