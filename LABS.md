# Hands-On Performance & Concurrency Engineering Labs

This document catalogs the hands-on database labs distributed across the curriculum. Every lab is reproducible on the baseline **PostgreSQL 18.6** environment with explicit seed schemas, measurement commands, and evidence-based analysis.

---

## 🧪 Master Lab Directory

| Lab ID | Module | Lab Name | Core Mechanics & Concepts Explored |
| :--- | :--- | :--- | :--- |
| **LAB-14.1** | [14-indexing/](14-indexing/) | Missing Index Impact | Seq Scan vs Index Scan, buffer read reduction, cache effects |
| **LAB-14.2** | [14-indexing/](14-indexing/) | Composite Index Ordering | Leftmost prefix seek vs full index scan, selectivity sorting |
| **LAB-16.1** | [16-explain-and-explain-analyze/](16-explain-and-explain-analyze/) | Bad Cardinality Estimates | Correlated column skew, statistics staleness, `ANALYZE` fix |
| **LAB-16.2** | [16-explain-and-explain-analyze/](16-explain-and-explain-analyze/) | Unexpected Sequential Scan | Non-sargable functions, data type mismatches, low selectivity |
| **LAB-17.1** | [17-query-optimization/](17-query-optimization/) | Slow Query Optimization | Eliminating correlated subquery loops via Hash Semi-Join |
| **LAB-17.2** | [17-query-optimization/](17-query-optimization/) | Deep OFFSET Pagination | Converting $O(N)$ high-OFFSET reads to $O(\log N)$ Keyset seeks |
| **LAB-19.1** | [19-isolation-and-locking/](19-isolation-and-locking/) | Deadlock Reproduction & Fix | Cyclic row-locking deadlocks (`40P01`), lock ordering rules |
| **LAB-19.2** | [19-isolation-and-locking/](19-isolation-and-locking/) | Lock Contention & Queuing | Exclusive table locks vs row locks, `NOWAIT`, `SKIP LOCKED` |
| **LAB-19.3** | [19-isolation-and-locking/](19-isolation-and-locking/) | Lost Update Under Read Committed | Concurrent balance updates, atomic increments, optimistic lock |
| **LAB-20.1** | [20-postgresql-sql/](20-postgresql-sql/) | Table Bloat & Autovacuum Tuning | MVCC dead tuple buildup, freeze limits, autovacuum tuning |
| **LAB-24.1** | [24-performance-debugging/](24-performance-debugging/) | Long-Running Open Transaction | `idle in transaction` locking horizon, WAL bloat investigation |
| **LAB-24.2** | [24-performance-debugging/](24-performance-debugging/) | Connection Pool Exhaustion | Process memory limits, high CPU context switching, PgBouncer |

---

## 🔬 Standard Lab Execution Protocol

Every lab follows an evidence-driven, 10-step protocol:

```
1. Initial State        → Baseline PostgreSQL configuration and table structure
2. Dataset              → Deterministic schema DDL and seed generation (100k - 10M rows)
3. Problem              → The realistic production symptom or SLA violation
4. Observation          → Query execution output or client error report
5. EXPLAIN / Metrics    → Detailed EXPLAIN (ANALYZE, BUFFERS) or pg_stat views
6. Investigation        → Root-cause hypothesis and bottleneck identification
7. Fix                  → DDL, index adjustment, query rewrite, or configuration change
8. Before Measurement   → Actual execution time and shared buffer reads before fix
9. After Measurement    → Actual execution time and shared buffer reads after fix
10. Lessons & Rules     → Architectural takeaway and interview defense
```

---

## 📋 Selected Lab Walkthrough Specifications

### Lab 14.1: Missing Index Impact
- **Location**: `14-indexing/labs/lab-01-missing-index.md`
- **Objective**: Demonstrate the transition from a disk-bound Sequential Scan across 1,000,000 rows to a sub-millisecond B-Tree Index Scan.
- **Dataset**: `orders` table (1M rows) with `customer_id`, `order_date`, `status`, `total_amount`.
- **Command**:
  ```sql
  EXPLAIN (ANALYZE, BUFFERS)
  SELECT * FROM orders WHERE customer_id = 45892;
  ```
- **Analysis Focus**: Compare `Buffers: shared hit=... read=...` between Seq Scan and B-Tree Index Scan.

### Lab 14.2: Composite Index Ordering
- **Location**: `14-indexing/labs/lab-02-composite-ordering.md`
- **Objective**: Prove why `(status, created_at)` is superior to `(created_at, status)` when filtering by equality on `status` and range on `created_at`.
- **Measurement**: Measure buffer page traversals when the index leftmost prefix rule is violated.

### Lab 16.1: Bad Cardinality Estimates
- **Location**: `16-explain-and-explain-analyze/labs/lab-01-bad-estimates.md`
- **Objective**: Induce a planner failure where estimated rows = 1 but actual rows = 50,000 due to correlated columns (`make` and `model`), triggering an catastrophic Nested Loop join.
- **Remediation**: Create multivariate statistics using `CREATE STATISTICS`.

### Lab 19.1: Deadlock Reproduction & Resolution
- **Location**: `19-isolation-and-locking/labs/lab-01-deadlock.md`
- **Objective**: Concurrently execute two transactions locking rows A and B in opposing sequence to trigger PostgreSQL error `40P01: deadlock detected`.
- **Remediation**: Enforce deterministic resource ordering in application and SQL transaction logic.

### Lab 19.3: Lost Update Simulation
- **Location**: `19-isolation-and-locking/labs/lab-03-lost-update.md`
- **Objective**: Simulate two concurrent bank account balance updates under default `READ COMMITTED` isolation, causing one update to silently overwrite the other.
- **Remediation**: Atomic `UPDATE accounts SET balance = balance + 50 WHERE id = 1` vs `SELECT ... FOR UPDATE` vs Optimistic Locking (`version` column).
