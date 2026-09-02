# Production SQL & Database Engineering Checklist

A production-grade pre-flight checklist for deploying queries, schema changes, indexes, and transaction logic to mission-critical, high-traffic database clusters.

---

## 🚀 1. Schema Migrations & DDL Checklist

- [ ] **Lock Timeouts Set**: All migration scripts explicitly execute `SET lock_timeout = '3s';` before running DDL to prevent blocking active queries.
- [ ] **Zero-Downtime Indexing**: All new production indexes use `CREATE INDEX CONCURRENTLY` (outside a transaction block).
- [ ] **Safe Column Additions**: New columns with default values in PostgreSQL 11+ are added without rewrite (`ALTER TABLE t ADD COLUMN col TYPE DEFAULT val;`), but check for volatile default functions (e.g. avoid non-immutable expressions during table rewrites).
- [ ] **Safe `NOT NULL` Constraints**: Adding `NOT NULL` to existing columns is done via `CHECK (col IS NOT NULL) NOT VALID;` followed by `ALTER TABLE t VALIDATE CONSTRAINT;` to avoid full table locks.
- [ ] **Expand / Contract Pattern**: Column renames or type changes are phased over multiple releases (add new col $\to$ dual write $\to$ backfill $\to$ read new col $\to$ drop old col).
- [ ] **No Long-Running Transactions in DDL**: DDL scripts do not wrap long-running backfills and table alterations in a single transaction block.

---

## ⚡ 2. Query Design & Sargability Checklist

- [ ] **No `SELECT *`**: All queries project explicit, necessary column lists.
- [ ] **Sargable Predicates**: Filters do not wrap indexed columns in functions (e.g., use `created_at >= '2026-01-01'` instead of `DATE(created_at) = '2026-01-01'`).
- [ ] **No Unbounded Queries**: All user-facing list endpoints enforce strict `LIMIT` bounds.
- [ ] **Keyset Pagination for Deep Feeds**: Endpoints paginating beyond 1,000 rows use cursor/keyset pagination (`WHERE (id, created_at) < (...)`) instead of `OFFSET`.
- [ ] **NULL-Safe Subqueries**: Anti-joins use `NOT EXISTS` or `LEFT JOIN ... WHERE NULL` rather than `NOT IN` with nullable columns.
- [ ] **Join Predicates Verified**: Every joined table has explicit join conditions to eliminate unintentional Cartesian products.

---

## 🔍 3. Indexing & Storage Checklist

- [ ] **Composite Index Ordering**: Equality filter columns precede range filter columns in multi-column indexes (`(status, created_at)`).
- [ ] **High Selectivity Verified**: Indexed columns have sufficient selectivity to justify B-Tree traversal over Sequential Scans.
- [ ] **Covering Indexes Evaluated**: High-frequency queries leverage `INCLUDE (...)` clauses for Index-Only Scans.
- [ ] **Partial Indexes Applied**: Skewed boolean flags use partial indexes (`CREATE INDEX ... WHERE active = true;`).
- [ ] **Unused Index Audit**: Tables are audited regularly via `pg_stat_user_indexes` to drop dead indexes that impose write amplification without query benefits.

---

## 🔒 4. Transactions, Concurrency & Locking Checklist

- [ ] **Minimal Transaction Scope**: Database transactions hold no third-party HTTP calls, disk I/O, or long CPU computations.
- [ ] **Deterministic Lock Ordering**: Concurrent operations modifying multiple rows acquire locks in a globally consistent order (e.g., sort by ID ascending before locking).
- [ ] **Non-Blocking Queue Processing**: Background worker polling queries use `SELECT ... FOR UPDATE SKIP LOCKED LIMIT 10`.
- [ ] **Appropriate Isolation Level**: `REPEATABLE READ` or `SERIALIZABLE` transactions have retry loops to handle serialization failures (`40001`).
- [ ] **Idle Transaction Timeout**: Global and session level timeouts configured (`idle_in_transaction_session_timeout = '30s'`).

---

## 🛡️ 5. Security & Access Control Checklist

- [ ] **Parameterized Queries**: 100% of dynamic queries use prepared statement parameters (`?` or `$1`); zero string concatenation.
- [ ] **Principle of Least Privilege**: Application database users only hold permissions on required tables (`SELECT`, `INSERT`, `UPDATE`, `DELETE`); no `SUPERUSER` or `CREATEROLE` in application pools.
- [ ] **Row-Level Security (RLS)**: Multi-tenant database tables enforce RLS policies keyed to `current_setting('app.current_tenant_id')`.
- [ ] **Sensitive Data Masking**: PII/credit card columns are masked, encrypted, or separated into restricted access schemas.

---

## 📊 6. Observability & Performance Pre-Flight Checklist

- [ ] **`EXPLAIN (ANALYZE, BUFFERS)` Executed**: Query plans reviewed with realistic production-scale data volumes.
- [ ] **No Disk Spills**: Memory-intensive sorting and hash joins fit within configured `work_mem` without spilling to temporary disk files.
- [ ] **`pg_stat_statements` Enabled**: Long-term tracking enabled to monitor mean execution time, call counts, and buffer hit ratios.
- [ ] **Connection Pool Sized Properly**: Application pool sized to $\sim 2 \times \text{CPU cores}$ with PgBouncer mediating connection bursts.
