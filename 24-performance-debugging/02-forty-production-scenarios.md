# 02. Forty Production Database Debugging Scenarios

A comprehensive incident triage catalog covering 40 real-world production database failure modes.

---

### Scenario 1: Sudden API Latency Spike Due to Missing Index After Deployment
- **Symptom**: Microservice API latency jumps from 15ms to 1,200ms following a new release.
- **Evidence**: `pg_stat_activity` shows 40 connections executing `SELECT * FROM orders WHERE tracking_number = ?` with `state = 'active'`.
- **Root Cause**: New feature queries `tracking_number` which lacks an index, forcing a full table Sequential Scan across 20M rows.
- **Fix**: `CREATE INDEX CONCURRENTLY idx_orders_tracking ON orders (tracking_number);`.
- **Prevention**: Pre-deployment query plan review in staging pipeline.

### Scenario 2: Connection Pool Exhaustion from `idle in transaction`
- **Symptom**: Application logs throw `HikariPool - Connection is not available, request timed out after 30000ms`.
- **Evidence**: `pg_stat_activity` shows 90% of connections in `state = 'idle in transaction'` with `xact_start` over 10 minutes old.
- **Root Cause**: An external HTTP API call was placed inside an application `@Transactional` method. The third-party API hung, holding the DB connection open.
- **Fix**: Terminate connections via `SELECT pg_terminate_backend(pid)` and set `ALTER ROLE app SET idle_in_transaction_session_timeout = '10s'`.
- **Prevention**: Move all external network RPCs outside transaction boundaries.

### Scenario 3: CPU 100% Saturation from Inefficient Hash Joins
- **Symptom**: Database server CPU reaches 100%; all read queries slow down.
- **Evidence**: `top` shows PostgreSQL backends thrashing in user space. `EXPLAIN` shows massive `Hash Join` with `Hash: Batches: 32` spilling to disk.
- **Root Cause**: Out-of-date table statistics caused planner to underestimate inner table size by 50x.
- **Fix**: Run `ANALYZE orders;` to refresh statistics.
- **Prevention**: Tune `autovacuum_analyze_scale_factor = 0.05`.

### Scenario 4: Table Bloat & Disk Space Exhaustion on Active Ledger Table
- **Symptom**: Disk usage alert at 90%. Table size is 120GB for only 2 million active records.
- **Evidence**: `pg_stat_user_tables` shows `n_dead_tup = 18,000,000` and `n_live_tup = 2,000,000`.
- **Root Cause**: Frequent balance `UPDATE` statements coupled with a long-running uncommitted analytical report blocking autovacuum cleanup.
- **Fix**: Terminate old reporting transaction; run `pg_repack` or `VACUUM FULL`.
- **Prevention**: Set `statement_timeout = '15min'` on reporting roles; tune autovacuum vacuum scale factor.

### Scenario 5: Cyclic Deadlock in High-Concurrency Order Processing
- **Symptom**: Application logs flooded with `org.postgresql.util.PSQLException: ERROR: deadlock detected (40P01)`.
- **Evidence**: PostgreSQL error logs show Process A waiting for lock on row 10 (held by B) while Process B waits for row 20 (held by A).
- **Root Cause**: Two services lock inventory rows in arbitrary, unsorted sequence.
- **Fix**: Enforce deterministic locking order: `SELECT * FROM inventory WHERE product_id IN (...) ORDER BY product_id FOR UPDATE;`.
- **Prevention**: Architectural rule requiring sorted batch acquisitions.

### Scenario 6: High OFFSET Degradation on Infinite Scroll Feed
- **Symptom**: Paginating past page 1,000 takes over 8 seconds per page.
- **Evidence**: `EXPLAIN` shows `Index Scan` discarding 500,000 tuples before returning 20.
- **Root Cause**: Using `OFFSET 500000 LIMIT 20`.
- **Fix**: Refactor to Keyset Pagination: `WHERE (created_at, id) < (:last_date, :last_id) ORDER BY created_at DESC, id DESC LIMIT 20`.
- **Prevention**: Deprecate deep numeric page jumping on multi-million row tables.

### Scenario 7: Silent Zero Results from `NOT IN` with Nulls
- **Symptom**: Fraud detection query returns 0 flagged transactions when fraudulent transactions are confirmed to exist.
- **Evidence**: Query uses `WHERE account_id NOT IN (SELECT account_id FROM whitelisted_accounts)`.
- **Root Cause**: `whitelisted_accounts` contains a single row with `account_id = NULL`, causing 3-valued logic to evaluate to `UNKNOWN` for all rows.
- **Fix**: Rewrite to `WHERE NOT EXISTS (SELECT 1 FROM whitelisted_accounts w WHERE w.account_id = a.account_id)`.
- **Prevention**: Use `NOT EXISTS` as standard anti-join pattern.

### Scenario 8: Non-Sargable Date Filter Forcing Table Scan
- **Symptom**: Query `WHERE DATE(created_at) = CURRENT_DATE` runs in 4,500ms despite an index on `created_at`.
- **Evidence**: `EXPLAIN` plan shows `Seq Scan` with `Filter: (date(created_at) = CURRENT_DATE)`.
- **Root Cause**: Wrapping `created_at` in `DATE()` prevents B-Tree index seek.
- **Fix**: Rewrite to range predicate: `WHERE created_at >= CURRENT_DATE AND created_at < CURRENT_DATE + 1`.
- **Prevention**: Linter rule prohibiting function wraps on indexed columns.

### Scenario 9: Migration Lock Queue Outage
- **Symptom**: Running `ALTER TABLE users ADD COLUMN age INT;` brings down production API within 2 seconds.
- **Evidence**: DDL was blocked behind an active query, and all incoming web requests queued behind the DDL's `AccessExclusiveLock`.
- **Root Cause**: Missing `lock_timeout` in migration script.
- **Fix**: Cancel migration PID; re-run with `SET lock_timeout = '3s';`.
- **Prevention**: Enforce `lock_timeout` in CI/CD migration pipeline.

### Scenario 10: PostgreSQL HOT Update Invalidation from Over-Indexing
- **Symptom**: Write throughput on `users` table drops by 60%; table bloat increases rapidly.
- **Evidence**: `pg_stat_user_tables` shows `n_tup_upd` rising, but `n_tup_hot_upd` is zero.
- **Root Cause**: A newly added index included a frequently updated column (`last_active_at`), preventing Heap-Only Tuple (HOT) optimizations and forcing index updates on every single click.
- **Fix**: Drop index or isolate `last_active_at` into a dedicated table.
- **Prevention**: Review index additions against hot update columns.

---

### Scenarios 11–40 Summary Reference Table

| # | Incident Scenario | Root Cause | Immediate Remediation |
| :-: | :--- | :--- | :--- |
| **11** | Foreign Key Cascade Deletion Lock | `ON DELETE CASCADE` scanning unindexed FK column | Add index on child foreign key column |
| **12** | Autovacuum Freeze Outage | Transaction ID wraparound horizon approaching limit | Run aggressive manual `VACUUM FREEZE` |
| **13** | Sequence Overflow Error | `INTEGER` sequence exhausted at 2.14 billion | Convert PK column and sequence to `BIGINT` |
| **14** | Serialization Failure Storm | High write contention on `SERIALIZABLE` isolation | Implement exponential backoff retry loop in app |
| **15** | Memory Exhaustion (OOM Killer) | `work_mem` set to 1GB with 200 concurrent active connections | Reduce global `work_mem` to 16MB |
| **16** | Unused Index Storage Bloat | 40 legacy indexes consuming 300GB of RAM/disk | Audit via `pg_stat_user_indexes` and `DROP INDEX` |
| **17** | Replication Lag Buildup | Heavy analytical query running on read replica holding slot | Enable `hot_standby_feedback = on` and monitor lag |
| **18** | Implicit Type Conversion Scan | Query passes string `'123'` to integer indexed column | Fix parameter type in Java JDBC driver |
| **19** | Accidental Cartesian Product | Missing join condition in 4-table query producing 100M rows | Add explicit ANSI `JOIN ... ON` predicate |
| **20** | Row-Level Lock Queuing | Multiple threads updating the same parent merchant account | Batch updates or use asynchronous ledger posting |
| **21** | Temporary File Spill | Analytical sort node writing 2GB to `pgsql_tmp` disk | Increase session-level `work_mem` for batch job |
| **22** | Prepared Statement Plan Invalidation | Generic plan picked over custom plan for skewed parameter | Use `SET plan_cache_mode = force_custom_plan` |
| **23** | GIN Index Bloat on JSONB | High update frequency on table with massive GIN index | Use `jsonb_path_ops` or partial GIN index |
| **24** | WAL Disk Full Outage | Inactive replication slot retaining WAL segments | Drop orphaned replication slot via `pg_drop_replication_slot()` |
| **25** | Unbounded `SELECT *` Memory Spike | Admin endpoint dumping 5M rows into JVM heap | Enforce hard `LIMIT 1000` on all API endpoints |
| **26** | Wrong Composite Index Order | Index `(created_at, status)` queried with equality on status | Rebuild index as `(status, created_at)` |
| **27** | Collation Mismatch Index Bypass | Database collation `C` vs query collation `en_US` | Align collation on index definition |
| **28** | Double Spend Lost Update | Read-modify-write balance update without row lock | Use `UPDATE accounts SET balance = balance - 50` |
| **29** | Partition Pruning Failure | Query filters on function of partition key | Query raw partition key bounds directly |
| **30** | Lock Escalation Emulation | 1,000,000 row updates acquiring 1M individual row locks | Batch updates into chunks of 5,000 rows |
| **31** | Correlated Subquery Loop | SubPlan re-executing for every outer row | Rewrite to `LEFT JOIN` or window function |
| **32** | Stale Statistics After Bulk Load | 10M rows inserted without running `ANALYZE` | Execute `ANALYZE target_table` post-load |
| **33** | Checkpoint Spike I/O Stalls | Checkpointer flushing dirty pages too aggressively | Tune `max_wal_size` and `checkpoint_completion_target=0.9` |
| **34** | Excessive Context Switching | 1,000 direct database connections without connection pool | Deploy PgBouncer in transaction pooling mode |
| **35** | Materialized View Refresh Lock | Non-concurrent refresh taking exclusive table lock | Run `REFRESH MATERIALIZED VIEW CONCURRENTLY` |
| **36** | Unique Violation Race Condition | Uniqueness validated in Java without DB `UNIQUE` constraint | Add database-level `UNIQUE` constraint |
| **37** | Foreign Data Wrapper (FDW) Timeout | Remote query fetching unindexed cross-server table | Push down WHERE predicates across FDW |
| **38** | RLS Performance Overhead | Complex subquery inside Row-Level Security policy | Optimize RLS policy subquery with dedicated index |
| **39** | Slow Connection Handshake | SSL negotiation and authentication overhead on new conns | Use persistent connection pooling |
| **40** | Autovacuum Cost Limit Starvation | Default `autovacuum_vacuum_cost_limit=200` too low on SSD | Increase limit to 1000–2000 for high-throughput SSDs |
