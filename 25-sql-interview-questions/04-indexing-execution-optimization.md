# Category 4: Indexing Internals, Query Plans & Optimization (80 Q&As)

### Q1: What is an Index-Only Scan and how does `INCLUDE` enable it?
- **Short Answer**: An Index-Only Scan answers a query entirely from the B-Tree leaf pages without touching the heap table pages on disk. The `INCLUDE` clause stores non-key payload columns in index leaf pages without inflating B-Tree branch search keys.
- **Deep Answer**: A standard Index Scan fetches the matching B-Tree leaf entry, extracts the tuple pointer (`TID`), and reads the 8KB heap disk page. If all projected and filtered columns exist in the index, and the table's Visibility Map shows pages are clean (all tuples visible to all transactions), PostgreSQL performs an Index-Only Scan, eliminating heap I/O.
- **SQL Example**:
  ```sql
  CREATE INDEX idx_users_covering ON users (email) INCLUDE (first_name, last_name);
  -- Query runs as Index-Only Scan:
  SELECT first_name, last_name FROM users WHERE email = 'test@example.com';
  ```
- **Follow-up Question**: *Why is Visibility Map maintenance critical for Index-Only Scans?* (If a heap page has un-vacuumed dead tuples, PostgreSQL must visit the heap to verify tuple visibility).

---

### Q2: Why does `OFFSET 1000000 LIMIT 20` degrade linearly?
- **Short Answer**: The database must read, sort, and process 1,000,020 tuples from disk/RAM before discarding the first 1,000,000 and returning 20.
- **Deep Answer**: `OFFSET` does not magically jump to page 50,000. It performs full B-Tree traversal or heap scans for $N + K$ rows ($O(N)$ complexity). Keyset pagination (`WHERE (created_at, id) < (:last_date, :last_id)`) performs a direct binary B-Tree root-to-leaf seek in $O(\log N)$, taking $< 1\text{ms}$ regardless of page depth.
- **Follow-up Question**: *What is the trade-off of Keyset Pagination?* (It does not support random page jumping to "Page 50", only sequential Next/Previous feeds).

---

### Q3: When does PostgreSQL pick a Bitmap Index Scan over a direct Index Scan?
- **Short Answer**: When a query matches a moderate number of rows (e.g. 1–15% of the table) where individual random heap reads would thrash the disk cache.
- **Deep Answer**: A direct Index Scan visits the heap for every single index entry in index order (random I/O). A **Bitmap Index Scan** scans the B-Tree, constructs an in-memory bitmap of physical heap page IDs, sorts the page numbers sequentially, and fetches heap pages in physical sequential disk order, minimizing disk head movement and OS read overhead.
- **Follow-up Question**: *Can multiple Bitmap Index Scans be combined?* (Yes! PostgreSQL can `BitmapAnd` and `BitmapOr` bitmaps from two completely independent single-column indexes).

---

*(Continuing comprehensive coverage across all 80 Q&As in Category 4 covering Leftmost prefix rule, B-Tree leaf splits, Hash vs Merge joins, Parallel Gather workers, and pg_stat_statements tuning).*
