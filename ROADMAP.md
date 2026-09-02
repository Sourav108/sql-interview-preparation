# 6-Week Structured SQL Interview Preparation Roadmap

This roadmap is engineered for backend engineers preparing for SDE2, Senior, Staff, and Database-heavy engineering roles within a 6-week preparation timeframe.

Every week follows a balanced 6-part learning cycle:
$$\text{Learn} \longrightarrow \text{Practice} \longrightarrow \text{Debug} \longrightarrow \text{Optimize} \longrightarrow \text{Interview} \longrightarrow \text{Revise}$$

---

## 📅 High-Level Schedule

| Week | Target Modules | Primary Focus | Milestones & Deliverables |
| :--- | :--- | :--- | :--- |
| **Week 1** | Modules 01–05 | Relational Modeling, Logical Order, Joins, Aggregation | E-commerce schema modeling, join multiplication lab, 30 coding problems |
| **Week 2** | Modules 06–11 | Subqueries, CTEs, Window Functions, NULL Logic, Dates | Top-N per group, recursive hierarchies, 3-valued logic pitfalls, 40 coding problems |
| **Week 3** | Modules 12–14 | Integrity Constraints, Normalization, B-Tree Indexing | Composite index ordering lab, partial & covering index benchmark, 30 problems |
| **Week 4** | Modules 15–19 | Execution Plans, EXPLAIN ANALYZE, Transactions, MVCC | Query optimization lab, deadlock triage lab, lost update concurrency simulation |
| **Week 5** | Modules 20–24 | PostgreSQL Advanced, Migrations, Security, Production Debug | Zero-downtime migration lab, autovacuum & bloat triage, 20 debugging runbooks |
| **Week 6** | Modules 25–30 | Question Banks, Complex Coding, Database Design, Mocks | 400+ interview Q&As review, 6 database design cases, 6 mock interview panels |

---

## 🗓️ Detailed Week-by-Week Breakdown

### Week 1: Foundations, Modeling, Joins & Aggregations
*Target Modules*: [01-sql-foundations](01-sql-foundations/), [02-data-modeling](02-data-modeling/), [03-select-filter-sort](03-select-filter-sort/), [04-joins](04-joins/), [05-aggregation](05-aggregation/)

- **Learn**:
  - Relational algebra foundations: Selection $\sigma$, Projection $\pi$, Cartesian Product $\times$, Joins $\bowtie$.
  - Logical Query Processing order (`FROM` $\to$ `ON` $\to$ `JOIN` $\to$ `WHERE` $\to$ `GROUP BY` $\to$ `HAVING` $\to$ `SELECT` $\to$ `DISTINCT` $\to$ `ORDER BY` $\to$ `LIMIT`).
  - Join mechanics: Nested loop vs Hash join vs Merge join concepts; Outer join NULL extension.
  - Aggregation groups, composite grouping keys, `HAVING` filters, and `FILTER (WHERE ...)`.
- **Practice**:
  - Solve 30 Easy/Medium coding problems from [26-sql-coding-problems](26-sql-coding-problems/) focusing on multi-table joins, self-joins, and aggregations.
- **Debug**:
  - Triage accidental Cartesian products caused by missing join predicates.
  - Fix row multiplication bugs in 1:N and M:N reporting queries.
- **Optimize**:
  - Replace non-sargable predicates (`WHERE YEAR(created_at) = 2026`) with index-friendly range bounds (`WHERE created_at >= '2026-01-01' AND created_at < '2027-01-01'`).
- **Interview**:
  - Practice explaining the difference between `WHERE` and `HAVING` with execution diagrams.
  - Defend `INNER JOIN` vs `LEFT JOIN` semantics when computing customer retention.
- **Revise**:
  - Review [SQL_CHEATSHEET.md](SQL_CHEATSHEET.md) Section 1–4.

---

### Week 2: Subqueries, Window Functions, NULLs & Temporal Analytics
*Target Modules*: [06-subqueries-and-cte](06-subqueries-and-cte/), [07-window-functions](07-window-functions/), [08-set-operations](08-set-operations/), [09-null-and-three-valued-logic](09-null-and-three-valued-logic/), [10-date-time-and-string](10-date-time-and-string/), [11-case-and-conditional-sql](11-case-and-conditional-sql/)

- **Learn**:
  - Correlated subqueries vs `EXISTS` vs `IN` vs `JOIN`.
  - Window framing syntax: `ROWS BETWEEN` vs `RANGE BETWEEN`, `UNBOUNDED PRECEDING`, `CURRENT ROW`.
  - Ranking semantics: `ROW_NUMBER()` vs `RANK()` vs `DENSE_RANK()`.
  - Kleene's 3-Valued Logic (`TRUE`, `FALSE`, `UNKNOWN`) and the `NOT IN (...) + NULL` trap.
  - `TIMESTAMPTZ`, UTC normalization, `DATE_TRUNC`, and rolling analytical windows.
- **Practice**:
  - Solve 40 Medium/Hard problems: Top-N per group, second-highest salary, running totals, moving 7-day revenue, recursive employee hierarchy traversal.
- **Debug**:
  - Debug a query returning 0 rows because of a `NOT IN` subquery containing a single `NULL`.
  - Fix window framing bounds yielding incorrect cumulative balances.
- **Optimize**:
  - Eliminate redundant CTE materializations; benchmark CTE vs derived subqueries.
- **Interview**:
  - Deliver a 5-minute explanation comparing `GROUP BY` vs `WINDOW FUNCTIONS`.
  - Walk an interviewer through the gaps-and-islands problem step-by-step.
- **Revise**:
  - Review [SQL_PATTERNS.md](SQL_PATTERNS.md) patterns 1–10.

---

### Week 3: Constraints, Normalization & Indexing Internals
*Target Modules*: [12-constraints](12-constraints/), [13-normalization](13-normalization/), [14-indexing](14-indexing/)

- **Learn**:
  - Database constraints: `PK`, `FK`, `UNIQUE`, `CHECK`, `EXCLUSION` constraints (`EXCLUDE USING gist`).
  - Normalization from 1NF through BCNF; functional dependencies and relational update/delete anomalies.
  - B-Tree index structure: Root, internal nodes, leaf nodes, TID pointers, and B-Tree traversals.
  - Composite indexes: Leftmost prefix rule, index selectivity, column ordering strategies.
  - Covering indexes (`INCLUDE`), Partial indexes (`WHERE deleted_at IS NULL`), and Index-Only Scans.
- **Practice**:
  - Complete [Lab 14.1: Missing Index & Query Plan Shift](LABS.md#lab-141-missing-index-impact) and [Lab 14.2: Composite Index Column Ordering](LABS.md#lab-142-composite-index-ordering).
- **Debug**:
  - Investigate why a query performs a Sequential Scan despite an index existing on the column (non-sargable functions, low selectivity, type mismatches).
- **Optimize**:
  - Refactor composite index `(status, created_at, user_id)` to match high-selectivity equality and range filter requirements.
- **Interview**:
  - Answer: *"Why can adding an index slow down an application? What are the write amplification costs?"*
  - Defend when to intentionally denormalize a reporting table vs using Materialized Views.
- **Revise**:
  - Review [SQL_ANTI_PATTERNS.md](SQL_ANTI_PATTERNS.md) on indexing and schema design.

---

### Week 4: Query Planner, EXPLAIN ANALYZE, Transactions & MVCC
*Target Modules*: [15-query-execution](15-query-execution/), [16-explain-and-explain-analyze](16-explain-and-explain-analyze/), [17-query-optimization](17-query-optimization/), [18-transactions-and-concurrency](18-transactions-and-concurrency/), [19-isolation-and-locking](19-isolation-and-locking/)

- **Learn**:
  - Query compilation pipeline: Parser $\to$ Planner $\to$ Optimizer $\to$ Executor.
  - Reading `EXPLAIN (ANALYZE, BUFFERS)`: Startup cost, total cost, actual rows, loops, buffer hits/reads.
  - Join execution mechanics: Nested Loop, Hash Join (with in-memory hash table vs batching), Merge Join.
  - ACID guarantees, Write-Ahead Logging (WAL), checkpointing, and commit flush mechanics.
  - PostgreSQL MVCC internals: `xmin`, `xmax`, tuple header visibility rules, vacuuming.
  - ANSI Isolation levels and anomalies: Dirty read, non-repeatable read, phantom read, lost update, write skew.
  - Locking: Row locks (`FOR UPDATE`, `FOR UPDATE SKIP LOCKED`), table locks, lock escalation, deadlock detection graph.
- **Practice**:
  - Complete [Lab 16.1: Bad Cardinality Estimates](LABS.md#lab-161-planner-estimation-skew), [Lab 19.1: Deadlock Reproduction & Resolution](LABS.md#lab-191-deadlock-reproduction), and [Lab 19.2: Lost Update Simulation](LABS.md#lab-192-lost-update-under-read-committed).
- **Debug**:
  - Triage a production query with a 100x estimation mismatch causing an inefficient Nested Loop join.
- **Optimize**:
  - Convert an expensive `OFFSET 500000 LIMIT 20` query into a sub-millisecond cursor-based / keyset pagination query.
- **Interview**:
  - Articulate PostgreSQL's `READ COMMITTED` vs `REPEATABLE READ` snapshot isolation mechanics.
  - Explain how `FOR UPDATE SKIP LOCKED` enables high-throughput database-backed task queues.
- **Revise**:
  - Review [PRODUCTION_SQL_CHECKLIST.md](PRODUCTION_SQL_CHECKLIST.md) transaction and locking rules.

---

### Week 5: PostgreSQL Extensions, Migrations, Security & Debugging
*Target Modules*: [20-postgresql-sql](20-postgresql-sql/), [21-schema-migrations](21-schema-migrations/), [22-sql-security](22-sql-security/), [23-sql-testing](23-sql-testing/), [24-performance-debugging](24-performance-debugging/)

- **Learn**:
  - PostgreSQL specific features: `JSONB` querying and GIN indexing, Array operators, Table partitioning.
  - Zero-downtime migrations: Expand / Contract pattern, `CREATE INDEX CONCURRENTLY`, adding `NOT NULL` columns safely in large tables.
  - Security & access control: Role-based permissions, Row-Level Security (RLS), parameterized queries.
  - Automated database testing with Testcontainers (PostgreSQL 18.6).
  - Production triage runbooks: Connection exhaustion, table/index bloat, autovacuum tuning, slow query logging.
- **Practice**:
  - Complete 15 scenarios from [24-performance-debugging](24-performance-debugging/).
  - Write integration tests verifying database constraints and concurrent race conditions.
- **Debug**:
  - Triage a high CPU saturation alert caused by bloat and missing statistics on a 50-million-row partitioned table.
- **Optimize**:
  - Tune autovacuum settings (`autovacuum_vacuum_scale_factor`, `autovacuum_vacuum_cost_limit`) to prevent table bloat.
- **Interview**:
  - Describe the complete zero-downtime migration steps to rename a column in a 100M-row production table.
  - Explain SQL injection defense-in-depth and Row-Level Security enforcement.
- **Revise**:
  - Review [PRODUCTION_SQL_CHECKLIST.md](PRODUCTION_SQL_CHECKLIST.md) zero-downtime migration checklist.

---

### Week 6: Comprehensive Question Banks, Coding, Design & Mock Interviews
*Target Modules*: [25-sql-interview-questions](25-sql-interview-questions/), [26-sql-coding-problems](26-sql-coding-problems/), [27-advanced-sql-patterns](27-advanced-sql-patterns/), [28-database-design-interviews](28-database-design-interviews/), [29-mock-interviews](29-mock-interviews/), [30-cheatsheets-and-revision](30-cheatsheets-and-revision/)

- **Learn & Master**:
  - Master all 6 Database System Design cases: E-Commerce, Double-Entry Banking Ledger, Ride-Hailing Booking, SaaS Subscriptions, Social Activity Feed, Telemetry Store.
  - Master the 7-step `R-E-Q-U-I-R-E` framework from [SQL_INTERVIEW_FRAMEWORK.md](SQL_INTERVIEW_FRAMEWORK.md).
- **Practice**:
  - Complete remaining Hard coding problems from [26-sql-coding-problems](26-sql-coding-problems/) (Sessionization, Retention cohorts, Funnels, Gaps and Islands).
- **Debug & Mock Panels**:
  - Conduct simulated mock interview rounds from [29-mock-interviews](29-mock-interviews/):
    - Round 1: SQL Foundations & Relational Semantics
    - Round 2: Live SQL Problem Solving
    - Round 3: Query Plan Analysis & Performance Tuning
    - Round 4: Database Architecture & Schema Design
    - Round 5: Production Incident & Concurrency Triage
    - Round 6: Transactions, MVCC & Locking
- **Review**:
  - Rapid-fire review of 400+ questions from [25-sql-interview-questions](25-sql-interview-questions/).
  - Final pass of [SQL_CHEATSHEET.md](SQL_CHEATSHEET.md) and [SQL_PATTERNS.md](SQL_PATTERNS.md).
