# 01. Window Function Anatomy and Core Patterns

## 1. GROUP BY vs Window Functions

The fundamental distinction that every interviewer tests:

| Dimension | `GROUP BY` | Window Function |
| :--- | :--- | :--- |
| **Output rows** | One row per group | One row per **input** row (no row reduction) |
| **Access to row data** | Only aggregated — individual row columns are lost | Full row data available alongside window result |
| **Use case** | Total per group | Rank within group, compare row to its peers |

```sql
-- GROUP BY: one row per department
SELECT department, AVG(salary) AS dept_avg
FROM employees GROUP BY department;

-- Window function: every employee row, with their dept avg alongside
SELECT
    first_name, department, salary,
    AVG(salary) OVER (PARTITION BY department) AS dept_avg,
    salary - AVG(salary) OVER (PARTITION BY department) AS diff_from_avg
FROM employees;
```

---

## 2. The OVER Clause Anatomy

```
FUNCTION() OVER (
    [PARTITION BY col1, col2]   ← defines the window partition (like GROUP BY)
    [ORDER BY col3 DESC]         ← defines ordering within the window
    [frame_clause]               ← defines which rows in the window are included
)
```

**All three sub-clauses are optional**:
- `OVER ()` — one window covering the entire result set.
- `OVER (PARTITION BY dept)` — separate window per department, no ordering.
- `OVER (PARTITION BY dept ORDER BY salary DESC)` — ranked within each department.

---

## 3. Ranking Functions

### 3.1 ROW_NUMBER — Unique Sequential Number

Always produces a unique integer per row within the partition, even for ties.

```sql
SELECT
    first_name, department, salary,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rn
FROM employees;
```

| first_name | department | salary | rn |
| :--- | :--- | :--- | :--- |
| Priya | Engineering | 150000 | 1 |
| Vikram | Engineering | 115000 | 2 |
| Rohan | Engineering | 120000 | 3 |
| Sneha | Engineering | 110000 | 4 |
| Arjun | Marketing | 105000 | 1 |
| Meera | Marketing | 95000 | 2 |

*(Row order for ties is non-deterministic without a tiebreaker column)*

### 3.2 RANK — Leaves Gaps After Ties

```sql
SELECT first_name, salary,
    RANK() OVER (ORDER BY salary DESC) AS rnk
FROM employees;
-- Values: [150000→1, 120000→2, 115000→3, 110000→4, 105000→5, 95000→6]
-- If two employees had salary 120000: [150000→1, 120000→2, 120000→2, 115000→4]
--                                                                         ↑ gap! (3 skipped)
```

### 3.3 DENSE_RANK — No Gaps After Ties

```sql
SELECT first_name, salary,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rnk
FROM employees;
-- If two employees had salary 120000: [150000→1, 120000→2, 120000→2, 115000→3]
--                                                                         ↑ no gap (3, not 4)
```

### 3.4 Top-N Per Group Pattern (Critical Interview Problem)

```sql
-- Top 2 highest-paid employees per department
WITH ranked_employees AS (
    SELECT
        first_name, department, salary,
        DENSE_RANK() OVER (
            PARTITION BY department
            ORDER BY salary DESC
        ) AS rnk
    FROM employees
)
SELECT first_name, department, salary, rnk
FROM ranked_employees
WHERE rnk <= 2;
```

> **Why can't we put `WHERE rnk <= 2` in the same query?**
> Window functions are computed in Step 7 (SELECT), but WHERE runs in Step 4 — before window functions exist. You must use a CTE or subquery to filter on the window result.

---

## 4. Navigation Functions: LAG, LEAD, FIRST_VALUE, LAST_VALUE

### 4.1 LAG — Access Previous Row

```sql
-- Month-over-Month revenue change
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', placed_at)::DATE AS month,
        SUM(total) AS revenue
    FROM orders
    WHERE status = 'DELIVERED'
    GROUP BY 1
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    revenue - LAG(revenue) OVER (ORDER BY month) AS delta,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
    1) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;
```

`LAG(col, N, default)` — looks N rows back; returns `default` if no prior row exists.
`LEAD(col, N, default)` — looks N rows ahead.

### 4.2 FIRST_VALUE / LAST_VALUE

```sql
-- Each employee's salary vs their department's highest and lowest earner
SELECT
    first_name, department, salary,
    FIRST_VALUE(salary) OVER (
        PARTITION BY department ORDER BY salary DESC
    ) AS dept_max_salary,
    LAST_VALUE(salary) OVER (
        PARTITION BY department ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS dept_min_salary
FROM employees;
```

> **LAST_VALUE trap**: By default, the window frame is `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`. `LAST_VALUE` with this default only sees rows up to and including the current row — not the actual last row of the partition. Always specify `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` for `LAST_VALUE`.

---

## 5. Window Framing

The frame clause defines which rows within the partition are included in the aggregate calculation for each row.

```
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW   ← cumulative from start
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW           ← rolling 7-row window
ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING           ← 3-row centered window
ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING   ← suffix aggregation
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING ← whole partition
```

### 5.1 Running Total

```sql
SELECT
    o.id,
    o.placed_at::DATE AS order_date,
    o.total,
    SUM(o.total) OVER (
        ORDER BY o.placed_at, o.id  -- tiebreaker ensures determinism
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM orders
WHERE status = 'DELIVERED'
ORDER BY o.placed_at, o.id;
```

### 5.2 7-Day Moving Average

```sql
WITH daily_revenue AS (
    SELECT placed_at::DATE AS day, SUM(total) AS revenue
    FROM orders WHERE status = 'DELIVERED'
    GROUP BY 1
)
SELECT
    day,
    revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        )::NUMERIC, 2
    ) AS rolling_7d_avg
FROM daily_revenue
ORDER BY day;
```

---

## 6. The Second-Highest Salary Problem

A perennial interview question:

```sql
-- Method 1: DENSE_RANK (handles ties correctly)
SELECT DISTINCT salary AS second_highest
FROM (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
    FROM employees
) ranked
WHERE rnk = 2;

-- Method 2: Subquery with LIMIT/OFFSET (simple but fragile on ties)
SELECT MAX(salary) AS second_highest
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);
```

**Interview follow-up**: *"What if there are two employees with the highest salary?"*
- `DENSE_RANK` approach: `rnk = 2` correctly finds the next distinct salary value.
- `MAX(salary) < MAX(salary)` approach: still works — it finds the max below the top value.
- `LIMIT 1 OFFSET 1` approach: **breaks** — skips one of the two tied highest rows, returning the correct second-distinct salary only by accident.

---

## 7. Interview Questions

**Q1: What is the key difference between GROUP BY and window functions?**
`GROUP BY` collapses rows — you get one output row per group, losing access to individual row values. Window functions compute results across a set of rows but **do not reduce the row count** — each input row produces one output row with the window result alongside it. This makes window functions essential for "rank within group," "compare row to its peers," and "access the previous/next row."

**Q2: When would you choose ROW_NUMBER over DENSE_RANK?**
Use `ROW_NUMBER` when you need exactly one result per partition regardless of ties (e.g., deduplication — pick one record to keep when there are duplicates). Use `DENSE_RANK` when ties should be treated equally and you want to find the "Nth distinct value" (e.g., the 3rd-highest salary where two people tied for 2nd should both have rank 2, and the next distinct salary has rank 3). Use `RANK` when you want gap semantics — skip rank numbers when there are ties.

**Q3: Why must window function results be filtered in a CTE or subquery rather than in WHERE?**
Window functions are computed in Step 7 of the logical query processing order, which is after `SELECT` expression evaluation. The `WHERE` clause runs in Step 4 — before window functions exist. Therefore `WHERE row_num = 1` fails because `row_num` doesn't exist at that point. The solution is to wrap the window function in a CTE or subquery, then filter in the outer query's `WHERE` clause.

**Q4: What goes wrong with LAST_VALUE and how do you fix it?**
The default window frame for ordered windows is `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`. `LAST_VALUE` with this frame returns the value of the *current* row, not the actual last row of the partition. The fix is to explicitly specify `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`, which extends the frame to the entire partition.

---

## 8. Further Reading
- [PostgreSQL 18 Documentation: Window Functions](https://www.postgresql.org/docs/18/functions-window.html)
- [PostgreSQL 18 Documentation: Window Function Processing](https://www.postgresql.org/docs/18/queries-table-expressions.html#QUERIES-WINDOW)
- [Use The Index, Luke: Window Functions](https://use-the-index-luke.com/sql/partial-results/window-functions)
