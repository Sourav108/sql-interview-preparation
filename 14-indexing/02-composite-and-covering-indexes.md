# 02. Composite Indexes and Covering Indexes (`INCLUDE`)

## 1. Composite Indexes: The Leftmost Prefix Rule

A **composite index** spans multiple columns: `CREATE INDEX idx_user_status_created ON users (status, created_at, country);`.

The B-Tree sorts entries first by `status`, then by `created_at` within identical statuses, then by `country`.

```
Composite Index: (status, created_at)
┌─────────────┬─────────────────────┬──────────────┐
│ status      │ created_at          │ TID          │
├─────────────┼─────────────────────┼──────────────┤
│ 'ACTIVE'    │ 2026-09-01 10:00:00 │ (page 1, 1)  │
│ 'ACTIVE'    │ 2026-09-01 12:00:00 │ (page 1, 2)  │
│ 'ACTIVE'    │ 2026-09-02 08:00:00 │ (page 2, 1)  │
│ 'PENDING'   │ 2026-09-01 09:00:00 │ (page 3, 1)  │
└─────────────┴─────────────────────┴──────────────┘
```

### 1.1 The Leftmost Prefix Rule
A query can perform an efficient B-Tree binary search seek **only if it supplies predicates starting from the leftmost column without gaps**:

| Query Filter | Can Use `(status, created_at, country)` Index? | Efficiency |
| :--- | :--- | :--- |
| `WHERE status = 'ACTIVE'` | ✅ Yes (Leftmost prefix) | Full B-Tree Seek |
| `WHERE status = 'ACTIVE' AND created_at > '2026-09-01'` | ✅ Yes (Leftmost prefix) | Full B-Tree Seek + Range Scan |
| `WHERE status = 'ACTIVE' AND country = 'IN'` | ⚠️ Partial (Seeks `status`, filters `country`) | Index Seek on `status`, then scans |
| `WHERE created_at > '2026-09-01'` | ❌ No direct seek (Skips leftmost column) | Full Index Scan or Table Seq Scan |
| `WHERE country = 'IN'` | ❌ No direct seek | Full Index Scan or Table Seq Scan |

---

## 2. The Gold Standard: Equality Columns Before Range Columns

**Rule**: *When designing a composite index for a query with both equality filters (`=`) and range filters (`<`, `>`, `BETWEEN`), place all equality columns FIRST in the index definition, followed by the range column.*

### Why?
Consider index `(created_at, status)` vs `(status, created_at)` for:
```sql
SELECT * FROM orders WHERE status = 'COMPLETED' AND created_at >= '2026-09-01';
```

- **Bad Index `(created_at, status)`**: The B-Tree is sorted by date first. The range scan on `created_at >= '2026-09-01'` scans across all statuses (PENDING, CANCELLED, COMPLETED) mixed together, testing `status = 'COMPLETED'` on every traversed leaf entry.
- **Optimal Index `(status, created_at)`**: The B-Tree seeks directly to the contiguous block of `'COMPLETED'` records, and within that block, performs a tight binary seek to `2026-09-01` and scans only the required range.

---

## 3. Covering Indexes & Index-Only Scans (`INCLUDE`)

In a standard Index Scan, every matching index tuple requires fetching the corresponding heap page to retrieve non-indexed columns.

An **Index-Only Scan** occurs when all columns requested by `SELECT`, `WHERE`, `ORDER BY`, and `GROUP BY` are contained entirely within the index itself — eliminating heap page reads completely.

### The `INCLUDE` Clause (PostgreSQL 11+)

```sql
-- Query:
SELECT first_name, last_name, email FROM users WHERE email = 'alice@example.com';

-- Standard composite index: (email, first_name, last_name)
-- Cost: All 3 columns participate in the B-Tree search key structure (wastes RAM).

-- Covering index using INCLUDE:
CREATE UNIQUE INDEX idx_users_email_covering
    ON users (email)
    INCLUDE (first_name, last_name);
```

### Advantages of `INCLUDE`:
1. `email` is the only search key enforcing uniqueness and tree navigation.
2. `first_name` and `last_name` are stored only at the leaf level as non-key payload columns.
3. Tree internal branch pages remain small and cache-friendly.
4. Queries for `first_name, last_name WHERE email = ?` execute via pure **Index-Only Scan**.
