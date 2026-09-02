# 03. Explicit Locking and High-Throughput Task Queues (`SKIP LOCKED`)

## 1. Row-Level Locking Modes

When multiple transactions need exclusive access to specific rows:

```sql
-- 1. Exclusive Write Lock: Blocks other UPDATEs, DELETEs, and FOR UPDATE locks
SELECT * FROM accounts WHERE id = 42 FOR UPDATE;

-- 2. Shared Read Lock: Blocks other UPDATEs, but allows other FOR SHARE readers
SELECT * FROM accounts WHERE id = 42 FOR SHARE;

-- 3. Non-Blocking Fail-Fast: Aborts immediately if row is already locked by another txn
SELECT * FROM accounts WHERE id = 42 FOR UPDATE NOWAIT;
```

---

## 2. High-Throughput Worker Queues (`FOR UPDATE SKIP LOCKED`)

Building an asynchronous job queue directly on PostgreSQL (e.g. outbox pattern, payment workers) without race conditions or lock contention:

```
Worker Thread 1 (claims Tasks 1, 2)            Worker Thread 2 (concurrently polling)
───────────────────────────────────            ──────────────────────────────────────
BEGIN;                                         BEGIN;
SELECT id, payload                             SELECT id, payload
FROM task_queue                                FROM task_queue
WHERE status = 'PENDING'                       WHERE status = 'PENDING'
ORDER BY id ASC                                ORDER BY id ASC
LIMIT 2                                        LIMIT 2
FOR UPDATE SKIP LOCKED;                        FOR UPDATE SKIP LOCKED;
→ Locks and returns IDs: [1, 2]                → SKIPS locked IDs [1, 2]!
                                               → Instantly locks & returns IDs: [3, 4]!
```

### Why `SKIP LOCKED` is a Game Changer:
1. **Zero Lock Waiting**: Worker 2 never blocks waiting for Worker 1's lock release.
2. **Zero Duplicate Work**: Worker 2 never processes the same tasks as Worker 1.
3. **High Parallelism**: 50 background worker threads can concurrently drain the queue at maximum I/O speed.
