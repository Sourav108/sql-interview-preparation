# 02. PostgreSQL MVCC Internals & Tuple Visibility

## 1. The Core MVCC Rule

> **Readers never block writers, and writers never block readers.**

PostgreSQL achieves concurrency by storing multiple physical versions of each row simultaneously in the heap table. An `UPDATE` does not overwrite existing bytes; it inserts a new tuple version and marks the old tuple version as obsolete.

---

## 2. Tuple Header System Columns: `xmin` and `xmax`

Every physical row on disk contains hidden system columns:

```
                               Physical Heap Tuple Layout
┌───────────────┬───────────────┬─────────────────┬───────────────────────────────┐
│ xmin: 105     │ xmax: 108     │ t_ctid: (0, 2)  │ User Data: (1, 'alice', 50.0) │
└───────────────┴───────────────┴─────────────────┴───────────────────────────────┘
```

- **`xmin`**: The Transaction ID (XID) that **created/inserted** this tuple version.
- **`xmax`**: The Transaction ID that **deleted or updated** this tuple version (0 if currently alive).
- **`ctid`**: The physical disk address pointer `(page_number, tuple_offset)`.

---

## 3. Tuple Lifecycle Example

1. **Transaction 100 `INSERT`s row**:
   - `xmin = 100`, `xmax = 0`, `data = ('Alice', 100.00)`
2. **Transaction 105 `UPDATE`s balance to 150.00**:
   - Old tuple modified in-place: `xmax` set to `105`.
   - New tuple inserted: `xmin = 105`, `xmax = 0`, `data = ('Alice', 150.00)`
3. **Transaction 102 queries the table**:
   - Compares its snapshot horizon against the tuples.
   - For old tuple: `xmin=100 <= 102` (committed before txn 102 started), `xmax=105 > 102` (deleted by a txn after 102 started).
   - $\implies$ **Transaction 102 reads the old tuple ($100.00$) cleanly without taking any locks!**

---

## 4. Dead Tuples and Autovacuum

Once all transactions older than `xmax=105` finish, the old tuple becomes invisible to every possible reader — a **dead tuple**.

- **`VACUUM`**: Reclaims space occupied by dead tuples on disk pages for future inserts.
- **Table Bloat**: Occurs when long-running transactions prevent `VACUUM` from advancing the global `xmin` cleanup horizon.
