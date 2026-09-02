# Lab 24.1: Long-Running Open Transaction Triage

## 1. Problem
A forgotten transaction sitting `idle in transaction` holds an old `xmin` snapshot horizon, preventing `AUTOVACUUM` from cleaning up dead tuples across the entire database and causing massive table bloat.

---

## 2. Detection Query

```sql
SELECT
    pid,
    usename,
    application_name,
    client_addr,
    state,
    now() - xact_start AS transaction_age,
    query
FROM pg_stat_activity
WHERE state = 'idle in transaction'
  AND now() - xact_start > INTERVAL '5 minutes'
ORDER BY transaction_age DESC;
```

---

## 3. Remediation
1. Terminate the offending backend process:
   ```sql
   SELECT pg_terminate_backend(:offending_pid);
   ```
2. Set cluster-wide safety timeout in `postgresql.conf`:
   ```sql
   ALTER SYSTEM SET idle_in_transaction_session_timeout = '30s';
   SELECT pg_reload_conf();
   ```
