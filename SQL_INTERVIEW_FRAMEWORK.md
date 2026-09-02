# The `R-E-Q-U-I-R-E` SQL Interview Framework

A structured, 7-step engineering framework to methodically solve any SQL problem or database interview question under time pressure.

```
       [R] Read the Requirement
                 ↓
      [E] Establish the Schema
                 ↓
     [Q] Query Simplest Baseline
                 ↓
      [U] Understand Edge Cases
                 ↓
      [I] Inspect Correctness
                 ↓
      [R] Refactor & Optimize
                 ↓
      [E] Explain Trade-offs
```

---

## Step 1: `R` — Read the Requirement

**Goal**: Convert ambiguous English business descriptions into precise relational operations.

- **Clarify the Business Metric**: What exact business entity represents 1 output row? (e.g., "One row per customer", "One row per department per month").
- **Identify Grain & Aggregation**: Are you returning raw granular entities or aggregated group summaries?
- **Clarify Ambiguities Early**:
  - *"Should customers with zero orders be included with a balance of $0, or omitted entirely?"* $\implies$ Determines `LEFT JOIN` vs `INNER JOIN`.
  - *"How should ties in rankings be handled?"* $\implies$ Determines `ROW_NUMBER()` vs `DENSE_RANK()`.
  - *"Is revenue calculated on `created_at` or `completed_at`?"* $\implies$ Determines filter column.

---

## Step 2: `E` — Establish the Schema & Cardinality

**Goal**: Mentally map the entity relationships, keys, and relational cardinality before writing code.

- **Trace Relational Paths**:
  - `Customers (1)` $\longleftrightarrow$ `(N) Orders` $\longleftrightarrow$ `(N) Order_Items` $\longleftrightarrow$ `(1) Products`
- **Identify Join Keys**: Primary Keys (`PK`) $\longleftrightarrow$ Foreign Keys (`FK`).
- **Evaluate Multiplicity Risks**:
  - Will joining `Orders` to `Order_Items` duplicate the `Orders.shipping_cost` when aggregating?
  - Will multiple active subscriptions cause row multiplication?

---

## Step 3: `Q` — Query the Simplest Correct Baseline

**Goal**: Write a readable, declarative, semantically valid baseline query.

- **Follow Logical Query Order**:
  1. `FROM` & `JOIN`: Collect all participating tables.
  2. `WHERE`: Filter individual rows before grouping.
  3. `GROUP BY`: Collapse rows into unique analytical buckets.
  4. `HAVING`: Filter aggregated groups.
  5. `SELECT`: Project desired columns, expressions, and window functions.
  6. `ORDER BY` & `LIMIT`: Sort and slice the final result set.
- **Use CTEs for Complexity**: Break multi-step logic into self-documenting Common Table Expressions rather than deeply nested derived subqueries.

---

## Step 4: `U` — Understand & Challenge Edge Cases

**Goal**: Stress-test the query against boundary conditions and tricky database phenomena.

| Edge Case Category | Specific Checks to Validate |
| :--- | :--- |
| **`NULL` Values** | Does `column = NULL` fail? (Must use `IS NULL`). Will `NOT IN (subquery)` fail if the subquery produces a `NULL`? |
| **Empty Sets** | What happens if a customer has 0 orders, a department has 0 employees, or a date range has 0 events? |
| **Ties & Duplicates** | Are there duplicate event rows? Does `RANK()` skip numbers while `DENSE_RANK()` does not? |
| **Division by Zero** | Does `SUM(success) / COUNT(*)` throw a division by zero error? (Use `NULLIF(count, 0)`). |
| **Case Sensitivity** | Does string filtering use `ILIKE` or `LOWER(col) = LOWER('input')` where case variance is expected? |

---

## Step 5: `I` — Inspect Correctness & Trace Execution

**Goal**: Mentally execute the query on sample rows and verify row counts.

- **Row Count Tracking**:
  - Start: `Table A` (10 rows)
  - After `LEFT JOIN Table B` (20 rows due to 1:N expansion)
  - After `WHERE B.status = 'COMPLETED'` (Filtered out NULLs $\implies$ turned outer join into inner join!)
- **Sanity Check Groupings**: Does every non-aggregated column in `SELECT` appear in the `GROUP BY` clause?
- **Verify Window Framing**: Does `SUM(amount) OVER (ORDER BY date)` accumulate properly, or did you intend `PARTITION BY customer_id`?

---

## Step 6: `R` — Refactor & Optimize for Scale

**Goal**: Transition from a working query to a production-grade, index-accelerated query.

- **Filter Pushdown**: Move filters as close to the storage layer as possible (e.g., filter inside `ON` or subquery before heavy joins).
- **Eliminate Unnecessary Work**: Replace `SELECT *` with explicit column projections; remove redundant `DISTINCT` calls.
- **Sargability Check**: Replace `WHERE DATE(created_at) = '2026-09-02'` with range predicates `WHERE created_at >= '2026-09-02' AND created_at < '2026-09-03'`.
- **Indexing Strategy**: Propose composite indexes matching the filter equality, range bounds, and join keys.
- **Pagination Strategy**: Propose keyset / cursor pagination (`WHERE id > :last_seen_id ORDER BY id LIMIT 20`) over deep `OFFSET`.

---

## Step 7: `E` — Explain Trade-offs & Engine Execution

**Goal**: Defend your architectural choices like a Staff-level backend engineer.

- **Explain Engine Cost & Plan**:
  - *"PostgreSQL will likely perform a Hash Join if the inner table fits in `work_mem`, or fall back to an Index Scan / Nested Loop if highly selective."*
- **Discuss Trade-offs**:
  - *Window Function vs Self-Join*: *"The window function performs a single sequential scan + sort ($O(N \log N)$), whereas a self-join requires $O(N^2)$ worst-case comparison."*
  - *Normalized Tables vs Materialized View*: *"For high-frequency OLTP writes, normalized tables prevent update anomalies; for heavy real-time analytics, an incrementally refreshed materialized view balances read latency."*
- **Discuss Concurrency & Locks**:
  - *"If this query runs concurrently with updates, we should use `FOR UPDATE SKIP LOCKED` to prevent worker thread contention."*
