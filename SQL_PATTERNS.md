# Master SQL Query Patterns Reference

A comprehensive, navigational index of essential SQL patterns. Each pattern provides recognition signals, conceptual mental models, generic templates, concrete PostgreSQL examples, common failure modes, and execution performance considerations.

> **Note**: Detailed problem sets and live coding exercises for these patterns are housed in [26-sql-coding-problems/](26-sql-coding-problems/).

---

## 📑 Pattern Catalog Index

| # | Pattern Name | Category | Primary Use Case |
| :-: | :--- | :--- | :--- |
| **01** | [Anti-Join (Exclusion Pattern)](#01-anti-join-exclusion-pattern) | Relational Joins | Find records in Table A with no matching records in Table B |
| **02** | [Semi-Join (Existence Pattern)](#02-semi-join-existence-pattern) | Relational Joins | Filter Table A based on presence in Table B without row duplication |
| **03** | [Top-N Records Per Group](#03-top-n-records-per-group) | Window Functions | Fetch top 1, 2, or N latest/highest records per partition |
| **04** | [Running Totals & Cumulative Aggregates](#04-running-totals--cumulative-aggregates) | Window Functions | Running account balances, cumulative revenue |
| **05** | [Moving / Rolling Averages](#05-moving--rolling-averages) | Window Framing | 7-day rolling active users, 30-day moving sales average |
| **06** | [Row Delta & Period-over-Period](#06-row-delta--period-over-period) | Window Navigation | Month-over-Month (MoM) revenue growth, latency changes |
| **07** | [Gaps and Islands](#07-gaps-and-islands) | Advanced Analytics | Identify continuous active streaks or missing consecutive IDs |
| **08** | [Sessionization](#08-sessionization) | Advanced Analytics | Group clickstream events into user sessions based on inactivity |
| **09** | [Funnel Analysis & Conversion](#09-funnel-analysis--conversion) | Advanced Analytics | Track sequential user drop-off across onboarding stages |
| **10** | [Cohort Retention Analysis](#10-cohort-retention-analysis) | Advanced Analytics | Measure repeat customer activity in subsequent months |
| **11** | [Hierarchical & Graph Traversal](#11-hierarchical--graph-traversal) | Recursive CTE | Organizational trees, bill-of-materials, network graphs |
| **12** | [Keyset / Cursor Pagination](#12-keyset--cursor-pagination) | Query Optimization | Scalable, constant-time pagination for infinite feeds |
| **13** | [Conditional Aggregation & Pivoting](#13-conditional-aggregation--pivoting) | Aggregation | Transform row-based statuses into column metrics |
| **14** | [Deduplication with Priority](#14-deduplication-with-priority) | Data Hygiene | Deduplicate records while keeping highest priority or latest row |
| **15** | [Date Range & Gap Filling](#15-date-range--gap-filling) | Temporal SQL | Fill missing calendar dates with 0 values using `generate_series` |

---

## Pattern Breakdowns

### 01. Anti-Join (Exclusion Pattern)
- **Recognition**: *"Find customers who have never placed an order"*, *"Find products never sold"*.
- **Mental Model**: Subtract set B from set A.
- **Template**:
  ```sql
  -- Approach A: NOT EXISTS (Recommended for clarity & NULL safety)
  SELECT a.*
  FROM table_a a
  WHERE NOT EXISTS (
      SELECT 1 FROM table_b b WHERE b.a_id = a.id
  );

  -- Approach B: LEFT JOIN ... WHERE IS NULL
  SELECT a.*
  FROM table_a a
  LEFT JOIN table_b b ON a.id = b.a_id
  WHERE b.a_id IS NULL;
  ```
- **Common Mistake**: Using `WHERE id NOT IN (SELECT a_id FROM table_b)`. If `table_b.a_id` contains even a single `NULL`, the entire `NOT IN` predicate evaluates to `UNKNOWN`, returning **zero rows**.
- **Performance**: PostgreSQL optimizer converts both `NOT EXISTS` and `LEFT JOIN ... WHERE NULL` into an Anti-Join plan (Hash Anti-Join or Merge Anti-Join).

---

### 02. Semi-Join (Existence Pattern)
- **Recognition**: *"Find all users who placed at least one order over $100"*.
- **Mental Model**: Check membership in target relation without multiplying outer rows.
- **Template**:
  ```sql
  SELECT u.*
  FROM users u
  WHERE EXISTS (
      SELECT 1
      FROM orders o
      WHERE o.user_id = u.id AND o.amount > 100
  );
  ```
- **Common Mistake**: Doing an `INNER JOIN orders` and then adding `DISTINCT users.*`. This forces an expensive duplicate elimination sort/hash step.
- **Performance**: Semi-join stops searching immediately on first match per outer row.

---

### 03. Top-N Records Per Group
- **Recognition**: *"Find the top 3 highest-earning employees in each department"*, *"Latest order per customer"*.
- **Mental Model**: Partition data into buckets, rank items inside each bucket, and filter rankings.
- **Template**:
  ```sql
  WITH ranked_items AS (
      SELECT
          t.*,
          DENSE_RANK() OVER (
              PARTITION BY department_id
              ORDER BY salary DESC
          ) AS rnk
      FROM employees t
  )
  SELECT *
  FROM ranked_items
  WHERE rnk <= 3;
  ```
- **PostgreSQL Specific Alternative (for N = 1)**:
  ```sql
  SELECT DISTINCT ON (department_id) *
  FROM employees
  ORDER BY department_id, salary DESC;
  ```
- **Common Mistake**: Attempting to use `WHERE rnk <= 3` directly in the same query without a CTE or subquery (window functions cannot appear in `WHERE`).
- **Performance**: Requires sorting per partition ($O(N \log N)$). An index on `(department_id, salary DESC)` allows index scans.

---

### 04. Running Totals & Cumulative Aggregates
- **Recognition**: *"Calculate account balance after each transaction"*, *"Cumulative revenue over time"*.
- **Mental Model**: Sliding cumulative window extending from start of partition to current row.
- **Template**:
  ```sql
  SELECT
      account_id,
      transaction_date,
      amount,
      SUM(amount) OVER (
          PARTITION BY account_id
          ORDER BY transaction_date, id
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS running_balance
  FROM transactions;
  ```
- **Common Mistake**: Omitting `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` when there are duplicate timestamps. Default `RANGE` framing will aggregate duplicate timestamps together into a single sum rather than row-by-row.
- **Performance**: Single pass window aggregation ($O(N)$) after sort.

---

### 05. Moving / Rolling Averages
- **Recognition**: *"Compute 7-day rolling average revenue"*, *"Smooth daily CPU spikes over 5 samples"*.
- **Mental Model**: Constrain the window frame to $K$ preceding rows or temporal range.
- **Template**:
  ```sql
  SELECT
      metric_date,
      daily_revenue,
      AVG(daily_revenue) OVER (
          ORDER BY metric_date
          ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
      ) AS rolling_7d_avg
  FROM daily_revenue_summary;
  ```
- **Common Mistake**: Assuming `ROWS BETWEEN 6 PRECEDING` calculates a true 7-day average if some calendar dates are missing from the table. Use date gap-filling (`generate_series`) first or temporal `RANGE` framing.

---

### 06. Row Delta & Period-over-Period
- **Recognition**: *"Compute Month-over-Month (MoM) revenue growth %"*, *"Time elapsed between consecutive user clicks"*.
- **Mental Model**: Compare current row with immediate predecessor using `LAG()`.
- **Template**:
  ```sql
  WITH monthly_sales AS (
      SELECT
          DATE_TRUNC('month', order_date)::DATE AS sales_month,
          SUM(total_amount) AS revenue
      FROM orders
      GROUP BY 1
  )
  SELECT
      sales_month,
      revenue,
      LAG(revenue) OVER (ORDER BY sales_month) AS prev_month_revenue,
      ROUND(
          (revenue - LAG(revenue) OVER (ORDER BY sales_month)) * 100.0 /
          NULLIF(LAG(revenue) OVER (ORDER BY sales_month), 0),
          2
      ) AS mom_growth_pct
  FROM monthly_sales;
  ```
- **Common Mistake**: Forgetting `NULLIF(..., 0)` causing runtime division by zero when previous period revenue is 0.

---

### 07. Gaps and Islands
- **Recognition**: *"Find user login streaks (consecutive days)"*, *"Find missing sequence invoice numbers"*.
- **Mental Model**: Continuous sequence differences produce a constant island identifier.
- **Template (Row-Difference Technique)**:
  ```sql
  WITH numbered_events AS (
      SELECT
          user_id,
          login_date,
          login_date - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date) * INTERVAL '1 day') AS island_group
      FROM user_logins
  )
  SELECT
      user_id,
      MIN(login_date) AS streak_start,
      MAX(login_date) AS streak_end,
      COUNT(*) AS streak_length_days
  FROM numbered_events
  GROUP BY user_id, island_group;
  ```
- **Common Mistake**: Not deduplicating multiple logins on the same day before computing `ROW_NUMBER()`.

---

### 08. Sessionization
- **Recognition**: *"Group user actions into sessions if inactive for more than 30 minutes"*.
- **Mental Model**: Detect step boundaries where $\Delta t > 30\text{ min}$, assign flag $1$, and compute cumulative sum to form session IDs.
- **Template**:
  ```sql
  WITH event_deltas AS (
      SELECT
          user_id,
          event_time,
          CASE
              WHEN event_time - LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time) > INTERVAL '30 minutes'
                   OR LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time) IS NULL
              THEN 1
              ELSE 0
          END AS is_new_session
      FROM user_events
  ),
  session_tagged AS (
      SELECT
          user_id,
          event_time,
          SUM(is_new_session) OVER (PARTITION BY user_id ORDER BY event_time) AS session_id
      FROM event_deltas
  )
  SELECT
      user_id,
      session_id,
      MIN(event_time) AS session_start,
      MAX(event_time) AS session_end,
      COUNT(*) AS total_events
  FROM session_tagged
  GROUP BY user_id, session_id;
  ```

---

### 09. Funnel Analysis & Conversion
- **Recognition**: *"What percentage of users progress from View $\to$ Cart $\to$ Checkout $\to$ Purchase?"*
- **Mental Model**: Aggregate binary flags for chronological event completion.
- **Template**:
  ```sql
  WITH user_funnel_stages AS (
      SELECT
          user_id,
          MAX(CASE WHEN event_name = 'view_product' THEN 1 ELSE 0 END) AS step_view,
          MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS step_cart,
          MAX(CASE WHEN event_name = 'checkout_start' THEN 1 ELSE 0 END) AS step_checkout,
          MAX(CASE WHEN event_name = 'purchase_complete' THEN 1 ELSE 0 END) AS step_purchase
      FROM tracking_events
      GROUP BY user_id
  )
  SELECT
      SUM(step_view) AS total_viewers,
      SUM(CASE WHEN step_view = 1 AND step_cart = 1 THEN 1 ELSE 0 END) AS reached_cart,
      SUM(CASE WHEN step_view = 1 AND step_cart = 1 AND step_checkout = 1 THEN 1 ELSE 0 END) AS reached_checkout,
      SUM(CASE WHEN step_view = 1 AND step_cart = 1 AND step_checkout = 1 AND step_purchase = 1 THEN 1 ELSE 0 END) AS reached_purchase
  FROM user_funnel_stages;
  ```

---

### 10. Cohort Retention Analysis
- **Recognition**: *"Measure 30-day, 60-day, and 90-day repeat purchase retention by signup month"*.
- **Mental Model**: Anchor each user to their acquisition cohort month, compute activity month offsets, and pivot.
- **Template**:
  ```sql
  WITH user_cohorts AS (
      SELECT
          user_id,
          DATE_TRUNC('month', MIN(created_at))::DATE AS cohort_month
      FROM users
      GROUP BY user_id
  ),
  user_activities AS (
      SELECT DISTINCT
          c.user_id,
          c.cohort_month,
          (EXTRACT(YEAR FROM o.order_date) - EXTRACT(YEAR FROM c.cohort_month)) * 12 +
          (EXTRACT(MONTH FROM o.order_date) - EXTRACT(MONTH FROM c.cohort_month)) AS month_offset
      FROM user_cohorts c
      JOIN orders o ON c.user_id = o.user_id
  )
  SELECT
      cohort_month,
      COUNT(DISTINCT user_id) AS total_cohort_users,
      COUNT(DISTINCT CASE WHEN month_offset = 0 THEN user_id END) AS month_0,
      COUNT(DISTINCT CASE WHEN month_offset = 1 THEN user_id END) AS month_1,
      COUNT(DISTINCT CASE WHEN month_offset = 2 THEN user_id END) AS month_2
  FROM user_activities
  GROUP BY cohort_month
  ORDER BY cohort_month;
  ```

---

### 11. Hierarchical & Graph Traversal
- **Recognition**: *"Find all direct and indirect subordinates under an executive"*, *"Compute total cost in assembly tree"*.
- **Mental Model**: Seed query (anchor member) followed by recursive union step.
- **Template**:
  ```sql
  WITH RECURSIVE org_tree AS (
      -- Anchor: Top-level manager
      SELECT id, name, manager_id, 1 AS depth
      FROM employees
      WHERE manager_id IS NULL
      
      UNION ALL
      
      -- Recursive member
      SELECT e.id, e.name, e.manager_id, ot.depth + 1
      FROM employees e
      JOIN org_tree ot ON e.manager_id = ot.id
  )
  SELECT * FROM org_tree ORDER BY depth, id;
  ```
- **Common Mistake**: Creating infinite recursion cycles when graphs contain loops (mitigate with cycle detection array in PostgreSQL: `ARRAY[id]`).

---

### 12. Keyset / Cursor-Based Pagination
- **Recognition**: *"Paginate millions of activity records without performance degradation on deep pages"*.
- **Mental Model**: Filter strictly greater than last observed index tuple `(created_at, id)`.
- **Template**:
  ```sql
  SELECT id, title, created_at
  FROM articles
  WHERE (created_at, id) < (:last_seen_created_at, :last_seen_id)
  ORDER BY created_at DESC, id DESC
  LIMIT 20;
  ```
- **Performance**: Performs an index seek in $O(\log N)$ rather than scanning and discarding $K$ rows ($O(K)$) as required by `OFFSET`.

---

### 13. Conditional Aggregation & Pivoting
- **Recognition**: *"Count pending, completed, and failed orders per merchant in a single row"*.
- **Mental Model**: Embed `CASE` statements inside aggregate functions.
- **Template**:
  ```sql
  SELECT
      merchant_id,
      COUNT(*) AS total_orders,
      COUNT(*) FILTER (WHERE status = 'COMPLETED') AS completed_count,
      COUNT(*) FILTER (WHERE status = 'FAILED') AS failed_count,
      SUM(amount) FILTER (WHERE status = 'COMPLETED') AS completed_volume
  FROM orders
  GROUP BY merchant_id;
  ```

---

### 14. Deduplication with Priority
- **Recognition**: *"Remove duplicate contact entries keeping the most recently verified record"*.
- **Mental Model**: Number duplicates with tie-breaker sorting criteria in `ROW_NUMBER()`.
- **Template**:
  ```sql
  WITH ranked_records AS (
      SELECT
          id,
          email,
          ROW_NUMBER() OVER (
              PARTITION BY email
              ORDER BY is_verified DESC, updated_at DESC, id DESC
          ) AS rn
      FROM contacts
  )
  DELETE FROM contacts
  WHERE id IN (
      SELECT id FROM ranked_records WHERE rn > 1
  );
  ```

---

### 15. Date Range & Gap Filling
- **Recognition**: *"Return daily order counts including zero for days with no sales"*.
- **Mental Model**: Generate complete date continuum via `generate_series()` and `LEFT JOIN` reality.
- **Template**:
  ```sql
  WITH calendar AS (
      SELECT generate_series(
          '2026-08-01'::DATE,
          '2026-08-31'::DATE,
          INTERVAL '1 day'
      )::DATE AS calendar_date
  )
  SELECT
      c.calendar_date,
      COALESCE(COUNT(o.id), 0) AS total_orders,
      COALESCE(SUM(o.amount), 0.00) AS total_revenue
  FROM calendar c
  LEFT JOIN orders o ON c.calendar_date = o.order_date
  GROUP BY c.calendar_date
  ORDER BY c.calendar_date;
  ```
