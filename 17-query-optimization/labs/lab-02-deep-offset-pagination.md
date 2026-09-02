# Lab 17.2: Deep OFFSET Pagination vs. Keyset Seek

## 1. Initial State & Dataset
A table of 1,000,000 timeline posts with index on `(created_at DESC, id DESC)`.

```sql
CREATE TABLE timeline_posts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

INSERT INTO timeline_posts (user_id, content, created_at)
SELECT
    (random()*1000)::int,
    'Post content ' || g,
    NOW() - (g || ' minutes')::INTERVAL
FROM generate_series(1, 1000000) g;

CREATE INDEX idx_timeline_created_id ON timeline_posts (created_at DESC, id DESC);
ANALYZE timeline_posts;
```

---

## 2. Benchmark 1: High-OFFSET Pagination (Page 25,000)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, user_id, created_at
FROM timeline_posts
ORDER BY created_at DESC, id DESC
LIMIT 20 OFFSET 500000;
```

### Measured Result:
```
Limit  (cost=17842.12..17842.83 rows=20 width=20) (actual time=142.610..142.615 rows=20 loops=1)
  Buffers: shared hit=4215 read=2840
  ->  Index Scan using idx_timeline_created_id on timeline_posts (cost=0.42..35684.24 rows=1000000 width=20) (actual time=0.038..108.412 rows=500020 loops=1)
        Buffers: shared hit=4215 read=2840
Execution Time: 142.645 ms
```
*Traversed and discarded 500,000 index rows, reading 7,055 8KB pages (56 MB of I/O) taking 142.6 ms.*

---

## 3. Benchmark 2: Keyset Pagination (Direct B-Tree Seek)

```sql
-- Assume last record seen on previous page was: created_at = '2025-09-18 14:40:00+00', id = 500001
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, user_id, created_at
FROM timeline_posts
WHERE (created_at, id) < ('2025-09-18 14:40:00+00', 500001)
ORDER BY created_at DESC, id DESC
LIMIT 20;
```

### Measured Result:
```
Limit  (cost=0.42..1.14 rows=20 width=20) (actual time=0.024..0.032 rows=20 loops=1)
  Buffers: shared hit=4 read=0
  ->  Index Scan using idx_timeline_created_id on timeline_posts (cost=0.42..35684.24 rows=500000 width=20) (actual time=0.022..0.028 rows=20 loops=1)
        Index Cond: (ROW(created_at, id) < ROW('2025-09-18 14:40:00+00'::timestamptz, 500001))
        Buffers: shared hit=4 read=0
Execution Time: 0.048 ms
```

---

## 4. Final Comparison

| Metric | High-OFFSET (`OFFSET 500000`) | Keyset Seek (`WHERE (created_at, id) < ...`) | Delta / Improvement |
| :--- | :--- | :--- | :--- |
| **Execution Time** | `142.64 ms` | `0.048 ms` | **2,971x faster** |
| **Buffer Pages Read** | `7,055 pages (56.4 MB)` | `4 pages (32 KB)` | **99.94% I/O reduction** |
| **Rows Traversed** | `500,020 rows` | `20 rows` | Exact seek |
