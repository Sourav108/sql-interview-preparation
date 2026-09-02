# 01. The Production Database Incident Triage Framework

```
     [1] Symptom Alert (e.g. CPU > 95%, Connection Pool Full, API Latency Spike)
                       ↓
     [2] Gather Hard Evidence (pg_stat_activity, pg_locks, pg_stat_statements)
                       ↓
     [3] Generate Differential Hypotheses (Index missing? Lock queue? Bloat?)
                       ↓
     [4] Deep Investigation (EXPLAIN ANALYZE, Buffer analysis, system catalog inspection)
                       ↓
     [5] Identify Root Cause
                       ↓
     [6] Apply Surgical Fix (Kill blocking PID, add CONCURRENT index, tune autovacuum)
                       ↓
     [7] Long-Term Prevention (Alert rules, lock timeouts, architectural redesign)
```

---

## The Production Triage SQL Toolkit

### 1. Identify Slow / Blocking Active Queries
```sql
SELECT
    pid,
    usename,
    now() - xact_start AS xact_duration,
    now() - query_start AS query_duration,
    state,
    wait_event_type,
    wait_event,
    query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_duration DESC NULLS LAST
LIMIT 10;
```

### 2. Identify Highest Resource-Consuming Queries via `pg_stat_statements`
```sql
SELECT
    query,
    calls,
    round(total_exec_time::numeric, 2) AS total_ms,
    round(mean_exec_time::numeric, 2)  AS mean_ms,
    rows,
    round((shared_blks_hit * 100.0 / nullif(shared_blks_hit + shared_blks_read, 0))::numeric, 2) AS cache_hit_pct
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```
