# Mock Interview Round 6: Transactions, MVCC & Locking Internals

## 1. Interviewer Prompt
> **Interviewer**: *"Explain how PostgreSQL Multi-Version Concurrency Control (MVCC) works under the hood. How does PostgreSQL allow a reader to read a consistent snapshot of data while writers are actively modifying the exact same rows without reading locks?"*

---

## 2. Senior Candidate Deep Dive
1. **Physical Tuple Headers (`xmin` and `xmax`)**:
   - PostgreSQL never modifies row bytes in-place.
   - An `UPDATE` inserts a new physical tuple with `xmin = current_xid` and writes `xmax = current_xid` to the old tuple header.
2. **Snapshot Horizons**:
   - When a reader executes a query, it receives a Snapshot containing:
     - Active uncommitted XIDs.
     - Completed transaction high-water mark.
3. **Visibility Evaluation**:
   - The reader inspects the old tuple: `xmin` is committed before reader started, `xmax` belongs to an in-flight or future writer $\implies$ **old tuple is visible**.
   - Reader inspects new tuple: `xmin` belongs to an in-flight uncommitted transaction $\implies$ **new tuple is invisible**.
   - Reader reads consistent state with zero lock waits.
4. **Vacuuming & Bloat**:
   - When all transactions older than `xmax` complete, the old tuple becomes a "dead tuple" reclaimed by `AUTOVACUUM`.
