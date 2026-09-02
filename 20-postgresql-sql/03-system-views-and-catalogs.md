# 03. Essential PostgreSQL System Catalogs & Monitoring Views

## 1. `pg_stat_activity` — Real-Time Query Monitoring

Inspect all active database connections, execution durations, and states:

```sql
SELECT
    pid,
    usename,
    client_addr,
    state,
    now() - xact_start AS txn_age,
    now() - query_start AS query_age,
    wait_event_type,
    wait_event,
    query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY txn_age DESC NULLS LAST;
```

---

## 2. Table & Index Disk Footprint

```sql
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid))       AS table_heap_size,
    pg_size_pretty(pg_indexes_size(relid))        AS all_indexes_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

---

## 3. Detecting Unused / Dead Indexes

Every unused index wastes storage and slows down `INSERT` and `UPDATE` operations:

```sql
SELECT
    schemaname,
    relname AS table_name,
    indexrelname AS index_name,
    idx_scan AS number_of_scans,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0                  -- Never scanned since last stats reset!
  AND indexrelname NOT LIKE '%_pkey' -- Exclude Primary Keys
ORDER BY pg_relation_size(indexrelid) DESC;
```
