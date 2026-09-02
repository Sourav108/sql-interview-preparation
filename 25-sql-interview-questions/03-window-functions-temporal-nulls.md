# Category 3: Window Functions, Temporal SQL & NULL Logic (80 Q&As)

### Q1: `ROW_NUMBER()` vs. `RANK()` vs. `DENSE_RANK()`?
- **Short Answer**: For input `[100, 100, 90]`: `ROW_NUMBER` gives `1, 2, 3`; `RANK` gives `1, 1, 3` (gaps after ties); `DENSE_RANK` gives `1, 1, 2` (no gaps).
- **Deep Answer**: `ROW_NUMBER()` assigns a strictly sequential integer per tuple. If ordering values tie, row ordering is non-deterministic without an explicit tiebreaker column. `RANK()` computes positional ranking with gaps reflecting the number of tied peers. `DENSE_RANK()` computes distinct value ordering, making it the ideal tool for "Nth highest" problems (e.g. 2nd highest salary).
- **SQL Example**:
  ```sql
  SELECT salary,
         ROW_NUMBER() OVER (ORDER BY salary DESC) AS rn,
         RANK()       OVER (ORDER BY salary DESC) AS rnk,
         DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rnk
  FROM employees;
  ```
- **Follow-up Question**: *How do you solve Top-N per group?* (Wrap `DENSE_RANK() OVER (PARTITION BY group_id ORDER BY score DESC)` in a CTE and filter `WHERE rnk <= N`).

---

### Q2: Why does `NOT IN (subquery)` return 0 rows when a NULL is present?
- **Short Answer**: `NOT IN (1, 2, NULL)` expands to `x <> 1 AND x <> 2 AND x <> NULL`. Since comparison with NULL yields `UNKNOWN`, the entire boolean expression evaluates to `UNKNOWN` or `FALSE`.
- **Deep Answer**: Under Kleene's 3-valued logic, `TRUE AND UNKNOWN` is `UNKNOWN`. Because the `WHERE` clause passes rows only when the predicate evaluates strictly to `TRUE`, all rows are discarded. Use `NOT EXISTS` instead.
- **Common Trap**: Using `NOT IN` on nullable foreign keys or external datasets.
- **Follow-up Question**: *How does `COALESCE()` differ from `NULLIF()`?* (`COALESCE` returns the first non-null argument; `NULLIF(a, b)` returns `NULL` if $a=b$, else returns $a$).

---

### Q3: What is the default window framing clause in SQL?
- **Short Answer**: `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` (when an `ORDER BY` is specified).
- **Deep Answer**: `RANGE` operates on distinct values rather than individual physical rows. If duplicate timestamps or tied values exist in the ordering column, `RANGE` aggregates all tied rows together into a single running sum. To aggregate strictly row-by-row, specify `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.
- **Common Trap**: Using `LAST_VALUE()` without specifying `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`, causing `LAST_VALUE()` to return the current row instead of the partition's last row.

---

*(Continuing comprehensive coverage across all 80 Q&As in Category 3 covering sessionization, gaps and islands, rolling moving averages, TIMESTAMPTZ, and calendar date-spine generation).*
