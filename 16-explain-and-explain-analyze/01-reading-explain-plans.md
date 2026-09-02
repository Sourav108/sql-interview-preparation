# 01. Reading EXPLAIN and EXPLAIN (ANALYZE, BUFFERS)

## 1. Syntax Variations

```sql
-- 1. Dry-run estimation (Does NOT execute the query — safe for massive writes)
EXPLAIN
SELECT * FROM orders WHERE total > 1000;

-- 2. Physical execution (Actually RUNS the query and records real timing!)
EXPLAIN ANALYZE
SELECT * FROM orders WHERE total > 1000;

-- 3. Production Gold Standard (Includes memory buffer hits, reads, and writes)
EXPLAIN (ANALYZE, BUFFERS, TIMING, COSTS)
SELECT * FROM orders WHERE total > 1000;
```

> **Warning**: `EXPLAIN ANALYZE DELETE FROM orders;` **WILL DELETE YOUR DATA**. `EXPLAIN ANALYZE` physically executes the statement. Always wrap modifications in a transaction and rollback when analyzing writes:
> ```sql
> BEGIN;
> EXPLAIN ANALYZE DELETE FROM orders WHERE status = 'CANCELLED';
> ROLLBACK;
> ```

---

## 2. Anatomy of a Plan Node

```
                                  Plan Node Structure
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ Node Type: Index Scan using idx_orders_customer_id on orders                           │
│ Theoretical Estimate : (cost=0.42..8.44 rows=1 width=32)                               │
│ Actual Measurement   : (actual time=0.015..0.022 rows=3 loops=1)                       │
│ Filter Evaluation    : Filter: (total > 100.00)                                        │
│ Rows Filtered Out    : Rows Removed by Filter: 2                                       │
│ Cache & I/O Buffers  : Buffers: shared hit=3 read=1 dirtied=0 written=0                │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### Deconstructing the Metrics

1. **`cost=0.42..8.44`**: Startup cost $0.42$, Total cost $8.44$ (unitless planner cost). **Estimated cost is NOT elapsed time.**
2. **`actual time=0.015..0.022`**: Time in milliseconds to return the first tuple ($0.015\text{ms}$) and all tuples ($0.022\text{ms}$).
3. **`loops=N`**: Number of times this node was executed.
   - **Crucial Rule**: **Total Actual Rows** $= \text{actual rows} \times \text{loops}$.
   - **Total Actual Time** $= \text{actual time} \times \text{loops}$.
4. **`Buffers: shared hit=3 read=1`**:
   - `hit=3`: 3 pages (24KB) were already in RAM (`shared_buffers`).
   - `read=1`: 1 page (8KB) had to be read from OS disk cache/storage.

---

## 3. The 4 Big Red Flags in EXPLAIN Output

| Red Flag | Visual in Plan | Underlying Problem |
| :--- | :--- | :--- |
| **Cardinality Skew** | `rows=1` vs `actual rows=50000` | Stale statistics; planner picked Nested Loop instead of Hash Join |
| **Disk Spill** | `Sort Method: external merge Disk: 4520kB` | `work_mem` too small; sorting spilled from RAM to disk temp files |
| **Filter Waste** | `Rows Removed by Filter: 990000` | Missing composite index; reading 1M rows to keep only 10,000 |
| **Buffer Exhaustion**| `Buffers: shared read=150000` (1.2GB) | High disk I/O; table needs partitioning, index, or caching |
