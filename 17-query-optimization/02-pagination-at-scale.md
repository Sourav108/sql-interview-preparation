# 02. Pagination at Scale: OFFSET vs. Keyset (Cursor) Pagination

## 1. The High-OFFSET Performance Trap

When fetching page 25,000 using traditional `OFFSET`:
```sql
SELECT id, created_at, title
FROM articles
ORDER BY created_at DESC, id DESC
LIMIT 20 OFFSET 500000;
```

### What the Database Engine Actually Does:
1. Traverses the B-Tree index and reads **500,020 rows** from disk/RAM.
2. Sorts or tracks 500,020 tuples in memory.
3. **Discards the first 500,000 rows**.
4. Returns only the final 20 rows.

$$\text{Time Complexity} = O(N) \quad \text{where } N = \text{OFFSET count}$$
Latency degrades linearly with page depth.

---

## 2. The Solution: Keyset / Cursor-Based Pagination

Instead of telling the database *"skip 500,000 rows"*, we tell it: *"seek directly to the last record we saw on the previous page and return the next 20"*.

```sql
-- Keyset seek query for next page:
SELECT id, created_at, title
FROM articles
WHERE (created_at, id) < (:last_seen_created_at, :last_seen_id)
ORDER BY created_at DESC, id DESC
LIMIT 20;
```

### What the Database Engine Does:
1. Performs a direct B-Tree root-to-leaf binary seek ($O(\log N)$) directly to `(:last_seen_created_at, :last_seen_id)`.
2. Scans exactly **20 leaf index entries**.
3. Fetches exactly 20 heap pages.

$$\text{Time Complexity} = O(\log N + K) \quad \text{where } K = \text{LIMIT (constant)}$$
Execution time is **$< 1\text{ms}$** regardless of whether you are on Page 1 or Page 100,000!

---

## 3. Comparison Matrix

| Dimension | `OFFSET / LIMIT` Pagination | Keyset / Cursor Pagination |
| :--- | :--- | :--- |
| **Performance on Page 1** | Fast ($< 1\text{ms}$) | Fast ($< 1\text{ms}$) |
| **Performance on Page 50,000**| Extremely slow ($2\text{s} - 30\text{s}$) | Instant ($< 1\text{ms}$) |
| **Stability Under Inserts** | ❌ Subject to page drift (duplicate/skipped rows when new rows inserted) | ✅ 100% deterministic (anchored to last viewed ID) |
| **Random Page Jumping** | Supports jumping directly to "Page 42" | Only supports "Next Page" / "Previous Page" (infinite scroll feeds) |
