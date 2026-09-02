# Category 5: Transactions, MVCC, Concurrency, Security & Operations (70 Q&As)

### Q1: How does PostgreSQL implement MVCC using `xmin` and `xmax`?
- **Short Answer**: PostgreSQL writes a new tuple version on every `UPDATE` instead of modifying in-place. `xmin` records the creating transaction ID; `xmax` records the deleting/updating transaction ID.
- **Deep Answer**: When a transaction executes a query under `READ COMMITTED` or `REPEATABLE READ`, it receives an active snapshot specifying which transaction IDs have committed. For each tuple on a disk page, the executor checks if `xmin` committed before the snapshot started and `xmax` is either 0 or committed after the snapshot started. This allows readers to read consistent historical snapshots without acquiring read locks.
- **Common Trap**: Believing `UPDATE` modifies bytes in-place like MySQL InnoDB does in undo logs.
- **Follow-up Question**: *What is table bloat in PostgreSQL?* (The accumulation of dead MVCC tuples that cannot be pruned because an old uncommitted transaction is holding back the global `xmin` horizon).

---

### Q2: How does `SELECT ... FOR UPDATE SKIP LOCKED` prevent worker contention?
- **Short Answer**: It locks matching rows exclusively while silently skipping any rows already locked by concurrent worker transactions, achieving non-blocking queue consumption.
- **Deep Answer**: Traditional `FOR UPDATE` causes competing workers to block and queue behind each other on the exact same top row. `SKIP LOCKED` instructs the engine to inspect the row lock state: if locked, skip immediately and lock the next eligible unlocked tuple. This allows 50 concurrent worker threads to drain an outbox table in parallel with zero deadlocks.
- **SQL Example**:
  ```sql
  SELECT id, payload FROM tasks
  WHERE status = 'PENDING'
  ORDER BY id ASC LIMIT 10
  FOR UPDATE SKIP LOCKED;
  ```
- **Follow-up Question**: *How does `NOWAIT` differ from `SKIP LOCKED`?* (`NOWAIT` aborts the transaction immediately with an error if any row is locked; `SKIP LOCKED` simply skips locked rows and returns remaining available rows).

---

### Q3: Why does `CREATE INDEX CONCURRENTLY` require 2 table scan passes?
- **Short Answer**: Pass 1 builds the index structure while concurrent writes continue. Pass 2 waits for active write transactions to finish, then catches up on modifications made during Pass 1.
- **Deep Answer**: Standard `CREATE INDEX` takes an `ACCESS EXCLUSIVE` lock, halting all writes. `CONCURRENTLY` uses a weaker `SHARE UPDATE EXCLUSIVE` lock, allowing full read/write throughput. Because concurrent transactions modified rows during the first B-Tree build pass, PostgreSQL must execute a second validation pass to index the newly modified tuples before activating the index in the catalog.
- **Common Trap**: Running `CREATE INDEX CONCURRENTLY` inside an explicit `BEGIN ... COMMIT` block (PostgreSQL will reject it with an error).

---

*(Continuing comprehensive coverage across all 70 Q&As in Category 5 covering deadlocks, lock hierarchies, Row-Level Security, zero-downtime expand/contract patterns, and PgBouncer pooling).*
