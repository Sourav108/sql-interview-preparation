# Master SQL & Relational Anti-Patterns Reference

A pragmatic, production-tested guide to SQL anti-patterns, why they degrade performance and correctness, how to detect them, and how to refactor them.

---

## 🛑 Summary of Anti-Patterns

| Anti-Pattern | Primary Impact | Detection Mechanism |
| :--- | :--- | :--- |
| [1. SELECT * in Production Queries](#1-select--in-production-queries) | Network/Memory Bloat, Breaks Index-Only Scans | Code review, high network egress |
| [2. Unnecessary DISTINCT Band-Aids](#2-unnecessary-distinct-band-aids) | High CPU/Sort Latency, Masks Join Bugs | Plan shows `Unique` / `Sort` nodes |
| [3. Non-Sargable Predicates & Functions on Indexed Columns](#3-non-sargable-predicates--functions-on-indexed-columns) | Forces Table Sequential Scans | `Seq Scan` on indexed columns in EXPLAIN |
| [4. The NOT IN with NULL Subquery Trap](#4-the-not-in-with-null-subquery-trap) | Logical Failure (Returns 0 Rows) | Empty result sets when data exists |
| [5. High-OFFSET Pagination](#5-high-offset-pagination) | Linear $O(N)$ Read Latency Degradation | Slow API responses on deep pages |
| [6. Accidental Cartesian Products (Missing Joins)](#6-accidental-cartesian-products-missing-joins) | Exploding Memory, Out of Memory (OOM) | Massive `Nested Loop` actual row counts |
| [7. N+1 Query Multiplications](#7-n1-query-multiplications) | Network Round-Trip Latency, DB Connection Saturation | Database query volume spikes |
| [8. Unbounded SELECT Queries](#8-unbounded-select-queries) | JVM/Service Memory Starvation | OutOfMemoryErrors, long lock holds |
| [9. Implicit Type Coercion / Collation Mismatches](#9-implicit-type-coercion--collation-mismatches) | Drops Index Scan to Seq Scan | `Filter: (col::text = 'val')` in EXPLAIN |
| [10. Long-Running Open Transactions](#10-long-running-open-transactions) | Locks Hot Tuples, Blocks Autovacuum, WAL Bloat | `idle in transaction` in `pg_stat_activity` |
| [11. Application-Only Uniqueness Validation](#11-application-only-uniqueness-validation) | Corrupted Data via Concurrent Race Conditions | Duplicate records in database |
| [12. Excessive & Blind Indexing](#12-excessive--blind-indexing) | Write Amplification, High Storage/RAM Usage | High write latency, zero-scan indexes |
| [13. Storing Everything as JSON / EAV Model](#13-storing-everything-as-json--eav-model) | Loss of Integrity, No Schema Enforcement | Complex JSON extraction queries |
| [14. Inappropriate Denormalization](#14-inappropriate-denormalization) | Update/Delete Anomalies, Data Inconsistency | Drift between denormalized aggregates and source |
| [15. Blindly Increasing Connection Pools](#15-blindly-increasing-connection-pools) | CPU Context Switching, Memory Thrashing | Elevated CPU wait with low throughput |

---

## Anti-Pattern Analysis

### 1. `SELECT *` in Production Queries
- **Why It Is Dangerous**: Reads unnecessary columns from disk/RAM, wastes network bandwidth, breaks Index-Only Scans, and can cause runtime application crashes if columns are added/reordered.
- **When It Happens**: Developers rapidly prototyping queries or ORM models fetching entire entity trees.
- **Symptoms**: High I/O reads, query planner picking Sequential Scans over Index-Only Scans.
- **How to Detect**: Audit query logs; check execution plans for absence of Index-Only Scans.
- **Better Approach**: Explicitly project only required columns (`SELECT id, first_name, email FROM ...`).
- **When Acceptable**: Ad-hoc terminal debugging in `psql` or `EXISTS (SELECT * FROM ...)` where projection is ignored.

---

### 2. Unnecessary `DISTINCT` Band-Aids
- **Why It Is Dangerous**: `DISTINCT` forces the database to sort or build a hash table of all projected columns to eliminate duplicates ($O(N \log N)$ or high memory). It frequently masks root-cause join bugs (e.g., 1:N join multiplication).
- **When It Happens**: Developer sees duplicate rows caused by an unconstrained `JOIN` and adds `DISTINCT` instead of fixing the relationship.
- **Symptoms**: High CPU usage, `Sort Method: external merge Disk` or `HashAggregate` in query plans.
- **How to Detect**: Search queries for `SELECT DISTINCT` on large multi-table joins.
- **Better Approach**: Fix join conditions or replace with a Semi-Join (`WHERE EXISTS (...)`).
- **When Acceptable**: Truly deduplicating distinct attribute values (e.g., `SELECT DISTINCT country FROM users`).

---

### 3. Non-Sargable Predicates & Functions on Indexed Columns
- **Why It Is Dangerous**: Wrapping indexed columns inside functions (e.g., `WHERE UPPER(email) = 'FOO'`, `WHERE DATE(created_at) = '2026-09-02'`) prevents B-Trees from performing binary search seeks, forcing full table Sequential Scans.
- **When It Happens**: Developers querying dates or case-insensitive text naturally using functions.
- **Symptoms**: High execution time, `Seq Scan` in `EXPLAIN` despite an index on `created_at`.
- **How to Detect**: Review query filters for expressions like `WHERE func(col) = val` or `WHERE col + 1 = 10`.
- **Better Approach**: Rewrite as sargable range predicates (`WHERE created_at >= '2026-09-02 00:00:00' AND created_at < '2026-09-03 00:00:00'`) or create an Expression Index (`CREATE INDEX idx_users_lower_email ON users (LOWER(email))`).
- **When Acceptable**: Tiny lookup tables (< 100 rows) where sequential scan is faster than index lookup.

---

### 4. The `NOT IN` with NULL Subquery Trap
- **Why It Is Dangerous**: In 3-Valued Logic, `val NOT IN (1, 2, NULL)` evaluates to `val <> 1 AND val <> 2 AND val <> NULL`. Since comparison with `NULL` yields `UNKNOWN`, the entire expression evaluates to `UNKNOWN` or `FALSE`. The query silently returns **0 rows**.
- **When It Happens**: Developers querying exclusion without realizing the child table nullable foreign key has a NULL.
- **Symptoms**: Queries mysteriously returning empty results in staging/production when records exist.
- **How to Detect**: Grep for `NOT IN (SELECT ...)`.
- **Better Approach**: Use `NOT EXISTS (SELECT 1 FROM ...)` or `WHERE id NOT IN (SELECT col FROM ... WHERE col IS NOT NULL)`.
- **When Acceptable**: When the subquery targets a column with a strict `NOT NULL` database constraint.

---

### 5. High-OFFSET Pagination
- **Why It Is Dangerous**: `OFFSET 1000000 LIMIT 20` requires the database engine to fetch 1,000,020 rows from disk, sort them, discard the first 1,000,000, and return 20. Latency grows linearly ($O(N)$) as page depth increases.
- **When It Happens**: Standard pagination UI controls on large tables (> 100k rows).
- **Symptoms**: Sub-millisecond latency on page 1, 5+ second latency on page 5,000.
- **How to Detect**: Look for `OFFSET` with variable user input in API endpoints.
- **Better Approach**: Keyset / Cursor pagination: `WHERE (created_at, id) < (:last_date, :last_id) ORDER BY created_at DESC, id DESC LIMIT 20`.
- **When Acceptable**: Admin tools where dataset is strictly small (< 1,000 rows).

---

### 6. Accidental Cartesian Products (Missing Joins)
- **Why It Is Dangerous**: Joining tables without sufficient join predicates results in an $M \times N$ row multiplication. A 10,000-row table joined with another 10,000-row table produces 100,000,000 rows, exhausting memory and crashing queries.
- **When It Happens**: Multiple table joins where one join condition was omitted in comma-separated `FROM` syntax or misconfigured `JOIN ... ON 1=1`.
- **Symptoms**: Exploding memory, runaway queries, gateway timeouts (HTTP 504).
- **How to Detect**: `Nested Loop` with astronomical `actual rows` in `EXPLAIN ANALYZE`.
- **Better Approach**: Use explicit ANSI-92 `JOIN ... ON` syntax and verify that every joined entity has a valid predicate.

---

### 7. N+1 Query Multiplications
- **Why It Is Dangerous**: Fetching 1 parent record and subsequently executing $N$ separate SQL queries for each child record results in $N+1$ network roundtrips, connection overhead, and transaction contention.
- **When It Happens**: Default lazy loading in ORMs (Hibernate, Prisma) inside iteration loops.
- **Symptoms**: Database connection spikes, thousands of identical queries with different IDs in `pg_stat_activity`.
- **How to Detect**: Enable query logging in dev/test; detect multiple queries executed per HTTP request.
- **Better Approach**: Join tables in a single query (`JOIN FETCH`), use batch loading (`WHERE id IN (...)`), or CTE aggregations.

---

### 8. Long-Running Open Transactions
- **Why It Is Dangerous**: In PostgreSQL MVCC, an active transaction holds an `xmin` snapshot horizon. This prevents `AUTOVACUUM` from cleaning up dead tuples created after that snapshot across the **entire database**, leading to catastrophic table bloat, disk exhaustion, and lock queues.
- **When It Happens**: Performing external HTTP API calls, file uploads, or complex business logic inside a database `@Transactional` block.
- **Symptoms**: `idle in transaction` status in `pg_stat_activity`, table size exploding despite low row count.
- **How to Detect**: Monitor `EXTRACT(EPOCH FROM now() - xact_start)` in `pg_stat_activity`.
- **Better Approach**: Keep transactions strictly confined to fast SQL operations. Execute external RPCs outside transaction boundaries. Set `idle_in_transaction_session_timeout = '30s'`.

---

### 9. Application-Only Uniqueness Validation
- **Why It Is Dangerous**: Validating uniqueness via application code (`if (!repo.existsByEmail(email)) repo.save(...)`) is vulnerable to race conditions under concurrent requests, resulting in duplicate entries.
- **When It Happens**: Developers trusting application logic without database schema enforcement.
- **Symptoms**: Duplicate customer accounts or orders in production.
- **How to Detect**: Inspect schemas for absence of `UNIQUE` constraints on business keys.
- **Better Approach**: Enforce uniqueness with a database `UNIQUE` constraint or unique index (`CREATE UNIQUE INDEX ...`).

---

### 10. Blindly Increasing Connection Pools
- **Why It Is Dangerous**: Each PostgreSQL connection is a dedicated OS process with dedicated memory. Setting connection pool size to 500+ on an 8-core server causes severe CPU context switching, lock thrashing, and cache evictions, degrading overall throughput.
- **When It Happens**: Engineers seeing connection timeout errors and increasing `max_connections` without tuning query latency.
- **Symptoms**: High CPU utilization (>95%), low query throughput, high context switches.
- **How to Detect**: Connection pool metrics showing hundreds of active connections with low queries/sec.
- **Better Approach**: Use connection poolers like PgBouncer (transaction pooling mode). Size backend connection pools to $2 \times \text{CPU cores}$.
