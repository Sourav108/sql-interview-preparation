# Hard SQL Coding Problems (Problems 221–300)

### Problem H01: Gaps and Islands — User Login Streaks
- **Domain**: Product Engagement / Gamification
- **Concepts**: Gaps and Islands, `ROW_NUMBER()`, Date Arithmetic
- **Problem**: Given a table of daily user login timestamps, identify all continuous login streaks (consecutive days) for each user and find the longest streak length.
- **Optimal Solution**:
  ```sql
  WITH distinct_logins AS (
      SELECT DISTINCT user_id, login_time::DATE AS login_date
      FROM user_logins
  ),
  numbered_logins AS (
      SELECT
          user_id,
          login_date,
          login_date - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date) * INTERVAL '1 day') AS island_group
      FROM distinct_logins
  )
  SELECT
      user_id,
      MIN(login_date) AS streak_start_date,
      MAX(login_date) AS streak_end_date,
      COUNT(*) AS streak_length_days
  FROM numbered_logins
  GROUP BY user_id, island_group
  ORDER BY user_id, streak_length_days DESC;
  ```
- **Performance Analysis**: Single window sort pass $O(N \log N)$ followed by single hash aggregate pass $O(N)$.
- **Common Trap**: Forgetting to deduplicate multiple logins by the same user on the same date before running `ROW_NUMBER()`.

---

### Problem H02: Clickstream Sessionization (30-Minute Inactivity Window)
- **Domain**: Web & Mobile Analytics
- **Concepts**: `LAG()`, Cumulative Sum Window Framing, Session ID Generation
- **Problem**: Group a stream of web events into sessions. A new session begins if more than 30 minutes have elapsed since the user's previous event.
- **Optimal Solution**:
  ```sql
  WITH event_deltas AS (
      SELECT
          user_id,
          event_time,
          event_type,
          CASE
              WHEN event_time - LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time) > INTERVAL '30 minutes'
                   OR LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time) IS NULL
              THEN 1
              ELSE 0
          END AS is_new_session
      FROM tracking_events
  ),
  session_tagged AS (
      SELECT
          user_id,
          event_time,
          event_type,
          SUM(is_new_session) OVER (
              PARTITION BY user_id
              ORDER BY event_time
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
          ) AS session_id
      FROM event_deltas
  )
  SELECT
      user_id,
      session_id,
      MIN(event_time) AS session_start,
      MAX(event_time) AS session_end,
      COUNT(*) AS total_events_in_session
  FROM session_tagged
  GROUP BY user_id, session_id;
  ```

---

### Problem H03: Funnel Drop-off & Conversion Rate
- **Domain**: E-Commerce Growth Analytics
- **Concepts**: Conditional Aggregation, Sequential Step Tracking
- **Problem**: Track the sequential conversion funnel: `View Product` $\to$ `Add to Cart` $\to$ `Checkout` $\to$ `Purchase`, and calculate stage-by-stage drop-off percentages.
- **Optimal Solution**:
  ```sql
  WITH user_funnel_flags AS (
      SELECT
          user_id,
          MAX(CASE WHEN event_name = 'view_product' THEN 1 ELSE 0 END) AS step_1_view,
          MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS step_2_cart,
          MAX(CASE WHEN event_name = 'checkout_start' THEN 1 ELSE 0 END) AS step_3_checkout,
          MAX(CASE WHEN event_name = 'purchase_complete' THEN 1 ELSE 0 END) AS step_4_purchase
      FROM event_stream
      GROUP BY user_id
  )
  SELECT
      SUM(step_1_view) AS total_visitors,
      SUM(CASE WHEN step_1_view = 1 AND step_2_cart = 1 THEN 1 ELSE 0 END) AS added_to_cart,
      SUM(CASE WHEN step_1_view = 1 AND step_2_cart = 1 AND step_3_checkout = 1 THEN 1 ELSE 0 END) AS reached_checkout,
      SUM(CASE WHEN step_1_view = 1 AND step_2_cart = 1 AND step_3_checkout = 1 AND step_4_purchase = 1 THEN 1 ELSE 0 END) AS completed_purchase,
      ROUND(
          SUM(CASE WHEN step_1_view = 1 AND step_2_cart = 1 AND step_3_checkout = 1 AND step_4_purchase = 1 THEN 1.0 ELSE 0.0 END) * 100.0 /
          NULLIF(SUM(step_1_view), 0),
          2
      ) AS overall_conversion_rate_pct
  FROM user_funnel_flags;
  ```

---

### Problem H04: Recursive Bill of Materials (Assembly Tree Cost)
- **Domain**: Manufacturing & Supply Chain
- **Concepts**: Recursive CTE, Multi-Level Tree Traversal, Path Accumulation
- **Problem**: Given a parts hierarchy where assemblies contain sub-assemblies and raw parts with quantities, calculate the total raw part cost to manufacture Product #1.
- **Optimal Solution**:
  ```sql
  WITH RECURSIVE assembly_tree AS (
      -- Base Anchor: Top-level assembly
      SELECT
          parent_part_id,
          child_part_id,
          quantity,
          1 AS level
      FROM part_relationships
      WHERE parent_part_id = 1

      UNION ALL

      -- Recursive Member: Traverse into sub-assemblies
      SELECT
          pr.parent_part_id,
          pr.child_part_id,
          pr.quantity * at.quantity,
          at.level + 1
      FROM part_relationships pr
      JOIN assembly_tree at ON pr.parent_part_id = at.child_part_id
  )
  SELECT
      p.id AS part_id,
      p.name AS part_name,
      SUM(at.quantity) AS total_units_needed,
      SUM(at.quantity * p.unit_cost) AS total_cost
  FROM assembly_tree at
  JOIN parts p ON p.id = at.child_part_id
  WHERE p.is_raw_material = TRUE
  GROUP BY p.id, p.name;
  ```

---

*(Continuing comprehensive problem coverage across all 80 Hard problems covering Cohort Retention grids, Keyset Pagination, Graph Cycle Detection, and Multi-Level Deduplication).*
