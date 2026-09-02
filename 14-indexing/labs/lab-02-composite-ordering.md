# Lab 14.2: Composite Index Column Ordering

## 1. Problem
A critical reporting query filters on exact `status = 'COMPLETED'` and date range `created_at >= NOW() - INTERVAL '7 days'`:
```sql
SELECT customer_id, total
FROM perf_orders
WHERE status = 'COMPLETED'
  AND created_at >= NOW() - INTERVAL '7 days';
```

Two candidate composite indexes exist:
- **Index A (Inverted)**: `(created_at, status)`
- **Index B (Optimal - Equality First)**: `(status, created_at)`

---

## 2. Benchmark Experiment

### Test with Index A: `(created_at, status)`
```sql
CREATE INDEX idx_perf_orders_created_status ON perf_orders (created_at, status);
ANALYZE perf_orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, total
FROM perf_orders
WHERE status = 'COMPLETED'
  AND created_at >= '2026-08-25 00:00:00+00';
```

**Result (Index A)**:
- Index scan traverses all 19,000 leaf rows created in the last 7 days across PENDING, COMPLETED, and CANCELLED statuses, evaluating `Filter: (status = 'COMPLETED')` on each.
- **Buffers hit**: `~340 pages`. Execution time: `~9.2 ms`.

---

### Test with Index B: `(status, created_at)`
```sql
DROP INDEX idx_perf_orders_created_status;
CREATE INDEX idx_perf_orders_status_created ON perf_orders (status, created_at);
ANALYZE perf_orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, total
FROM perf_orders
WHERE status = 'COMPLETED'
  AND created_at >= '2026-08-25 00:00:00+00';
```

**Result (Index B)**:
- Index seeks directly to the `'COMPLETED'` B-tree partition, then seeks directly to `created_at >= '2026-08-25'`, scanning *only* the ~6,300 matching completed rows. Zero non-matching rows traversed.
- **Buffers hit**: `~115 pages`. Execution time: `~2.8 ms` (over **3x faster**, 66% fewer buffer reads).

---

## 3. Core Rule
Always place **Equality filter columns before Range filter columns** in composite index definitions.
