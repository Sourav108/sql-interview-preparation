# Lab 14.1: Missing Index Impact

## 1. Initial State
PostgreSQL 18.6 with standard `shared_buffers = 128MB`. Target table has 1,000,000 order records without an index on `customer_id`.

## 2. Dataset Setup
```sql
-- DDL
CREATE TABLE perf_orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL,
    total NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

-- Seed 1,000,000 rows
INSERT INTO perf_orders (customer_id, status, total, created_at)
SELECT
    (random() * 50000)::INT + 1,
    (ARRAY['PENDING', 'COMPLETED', 'CANCELLED'])[floor(random()*3)+1],
    (random() * 500)::NUMERIC(10,2),
    NOW() - (random() * 365 || ' days')::INTERVAL
FROM generate_series(1, 1000000);

ANALYZE perf_orders;
```

## 3. Problem
An API endpoint fetching order history for a specific customer (`customer_id = 42890`) times out under production load.

## 4. Initial Observation & EXPLAIN Analysis
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM perf_orders WHERE customer_id = 42890;
```

### Initial Output (Before Fix):
```
Seq Scan on perf_orders  (cost=0.00..18456.00 rows=20 width=36) (actual time=0.042..48.312 rows=18 loops=1)
  Filter: (customer_id = 42890)
  Rows Removed by Filter: 999982
  Buffers: shared hit=8456
Planning Time: 0.082 ms
Execution Time: 48.345 ms
```

## 5. Investigation & Root Cause
The query planner is forced to execute a **Sequential Scan** across all 8,456 disk pages (67.6 MB) of the heap table, filtering 1,000,000 rows sequentially to find only 18 matching rows.

## 6. Fix & Remediation
Create a B-Tree index on `customer_id`:
```sql
CREATE INDEX idx_perf_orders_customer_id ON perf_orders (customer_id);
```

## 7. After Measurement
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM perf_orders WHERE customer_id = 42890;
```

### Output (After Fix):
```
Bitmap Heap Scan on perf_orders  (cost=4.44..78.12 rows=20 width=36) (actual time=0.031..0.048 rows=18 loops=1)
  Recheck Cond: (customer_id = 42890)
  Heap Blocks: exact=18
  Buffers: shared hit=21
  ->  Bitmap Index Scan on idx_perf_orders_customer_id  (cost=0.00..4.43 rows=20 width=0) (actual time=0.018..0.018 rows=18 loops=1)
        Index Cond: (customer_id = 42890)
        Buffers: shared hit=3
Planning Time: 0.124 ms
Execution Time: 0.068 ms
```

## 8. Before vs. After Comparison

| Metric | Before Fix (Seq Scan) | After Fix (Index Scan) | Improvement |
| :--- | :--- | :--- | :--- |
| **Execution Time** | `48.34 ms` | `0.068 ms` | **710x faster** |
| **Buffer Reads** | `8,456 pages (67.6 MB)` | `21 pages (168 KB)` | **99.75% I/O reduction** |
| **Rows Evaluated** | `1,000,000 rows` | `18 rows` | Direct seek |

## 9. Architectural Lessons
- High-selectivity queries fetching $<1\%$ of a table must have index support.
- Buffers read is the true currency of database scalability, not CPU frequency.
