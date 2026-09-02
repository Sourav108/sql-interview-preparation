# 01. ACID Properties and Write-Ahead Logging (WAL)

## 1. Deconstructing ACID

A **database transaction** is a logical unit of work that transitions the database from one valid consistent state to another.

```
       ┌─────────────────────────────────────────────────────────────┐
       │                        A - C - I - D                        │
       └──────────────────────────────┬──────────────────────────────┘
                                      │
       ┌──────────────────┬───────────┴───────────┬──────────────────┐
       ▼                  ▼                       ▼                  ▼
   Atomicity         Consistency              Isolation          Durability
 All or nothing;    Maintains schema      Concurrent txns      Committed data
 aborted txns       constraints & data    cannot observe       persists even if
 leave no trace.    invariants.           dirty uncommitted    power is lost
                                          state.               immediately.
```

---

## 2. Write-Ahead Logging (WAL) & Durability

How does PostgreSQL guarantee **Durability** without forcing an expensive random disk write for every single modified table page?

```
Client UPDATE
      │
      ▼
1. Modify 8KB Table Page in RAM (shared_buffers) → Marked "DIRTY"
      │
      ▼
2. Write small change record to Write-Ahead Log (WAL Buffer)
      │
      ▼
3. On COMMIT: fsync() WAL buffer sequentially to disk (pg_wal)
      │
      ▼
4. Return SUCCESS to Client! (Fast sequential disk write!)
      │
      │ (Asynchronously later in the background)
      ▼
5. Checkpointer flushes Dirty 8KB Pages from RAM to actual heap files.
```

### The WAL Invariant Rule
*A dirty data page in RAM can NEVER be written to the database heap files on disk until the WAL records describing the change have first been safely flushed to persistent storage (`fsync`).*

---

## 3. Crash Recovery Mechanics (ARIES Overview)

If the server loses power unexpectedly:
1. **Redo Phase (Roll Forward)**: Replays all WAL records since the last checkpoint to restore RAM buffer state.
2. **Undo Phase (Roll Back)**: Scans backwards to identify transactions that were active (uncommitted) at the time of the crash and rolls back their modifications.
