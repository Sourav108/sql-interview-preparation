# Mock Interview Round 5: Production Incident & Concurrency Triage

## 1. Interviewer Prompt
> **Interviewer**: *"It's 2:00 PM on Cyber Monday. API p99 latency spikes from 20ms to 30 seconds. Application logs report connection pool timeout errors. Database CPU is at only 15%, but disk I/O and active connection count are maxed out. How do you triage this live incident step-by-step?"*

---

## 2. Senior Candidate Triage Runbook
1. **Immediate Inspection via `pg_stat_activity`**:
   ```sql
   SELECT pid, state, wait_event_type, wait_event, now() - xact_start AS duration, query
   FROM pg_stat_activity WHERE state != 'idle' ORDER BY duration DESC;
   ```
2. **Identify Lock Queue**:
   - Check `wait_event_type = 'Lock'`.
   - Discover a long-running migration or analytical query holding an exclusive lock on the `orders` table.
3. **Surgical Emergency Fix**:
   - Gracefully cancel or terminate the blocking PID:
     ```sql
     SELECT pg_cancel_backend(:blocking_pid);
     ```
   - Pool immediately drains, p99 latency recovers to 20ms.
4. **Post-Mortem & Permanent Remediation**:
   - Set global `lock_timeout = '3s'` and `idle_in_transaction_session_timeout = '30s'` on application roles.
   - Configure PgBouncer in transaction pooling mode.
