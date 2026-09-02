# Lab 19.2: Row Lock Contention Diagnosis via `pg_locks`

## 1. Problem
Under heavy concurrent order placements, thread pools experience latency spikes. Developers suspect multiple backend transactions are waiting on row-level locks on the same hot merchant account.

---

## 2. Investigation Query: Identifying Blocking & Blocked PIDs

Run this query in `psql` to diagnose active lock queues and identify the root blocker:

```sql
SELECT
    blocked_locks.pid     AS blocked_pid,
    blocked_activity.usename  AS blocked_user,
    blocking_locks.pid    AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query    AS blocked_statement,
    blocking_activity.query   AS blocking_statement,
    now() - blocked_activity.query_start AS waiting_duration
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.GRANTED;
```

---

## 3. Remediation
1. Terminate the blocking PID if it is stuck `idle in transaction`:
   ```sql
   SELECT pg_cancel_backend(:blocking_pid);    -- Graceful interrupt
   SELECT pg_terminate_backend(:blocking_pid); -- Force kill
   ```
2. Set transaction timeout guardrails:
   ```sql
   ALTER ROLE app_user SET lock_timeout = '2s';
   ALTER ROLE app_user SET idle_in_transaction_session_timeout = '30s';
   ```
