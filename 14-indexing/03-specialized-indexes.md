# 03. Specialized PostgreSQL Index Types

## 1. Partial Indexes (Filtered Indexes)

A **Partial Index** indexes only a subset of table rows satisfying a `WHERE` predicate.

```sql
-- Use Case 1: Unprocessed task queue items (99% of queue is PROCESSED)
CREATE INDEX idx_tasks_unprocessed
    ON tasks (id)
    WHERE status = 'PENDING';

-- Use Case 2: Soft delete patterns (95% active rows, 5% deleted)
CREATE UNIQUE INDEX idx_users_active_email
    ON users (email)
    WHERE deleted_at IS NULL;
```

### Advantages:
- **Tiny Storage Footprint**: Only indexed rows occupy B-Tree pages (e.g. 10MB instead of 2GB).
- **Fast Writes**: Inserts and updates for non-matching rows (`status = 'PROCESSED'`) bypass index writes entirely.

---

## 2. Expression / Functional Indexes

When queries filter on computed values, a standard index on the raw column is ignored (non-sargable). An **Expression Index** stores the precomputed output of a deterministic function.

```sql
-- Query:
SELECT * FROM customers WHERE LOWER(email) = 'alice@example.com';

-- Expression Index:
CREATE INDEX idx_customers_lower_email
    ON customers (LOWER(email));
```

---

## 3. Overview of Other Index Types in PostgreSQL

| Index Type | Underlying Data Structure | Ideal Workload & Operators |
| :--- | :--- | :--- |
| **B-Tree** (Default) | Balanced multi-way search tree | General OLTP, `=`, `<`, `>`, `BETWEEN`, `ORDER BY` |
| **Hash** | Bucket-based hash table | Fast equality-only lookups (`=`) (WAL-logged in PG 10+) |
| **GIN** (Generalized Inverted) | Inverted index mapping elements to row IDs | Full-text search, `JSONB` containment (`@>`), Arrays (`&&`) |
| **GiST** (Generalized Search Tree) | Balanced tree for arbitrary hierarchical data | Geometric, Exclusion constraints, IP address ranges |
| **BRIN** (Block Range Index) | Stores min/max value per physical page range | Massive append-only time-series tables sorted by date |
