# 03. Parallel Query Execution in PostgreSQL

## 1. When Parallel Queries Trigger

PostgreSQL can dynamically spawn background worker processes to parallelize large analytical scans, joins, and aggregations when:
1. The table size exceeds `min_parallel_table_scan_size` (default 8MB).
2. The estimated cost exceeds `parallel_setup_cost` and `parallel_tuple_cost`.
3. The query does not hold an active write lock or execute non-parallel-safe functions (e.g. random number generators or sequence modifications).

---

## 2. Core Parallel Execution Nodes in `EXPLAIN`

```
                                 Gather
                      (Collects streams from workers)
                                   │
              ┌────────────────────┴────────────────────┐
              ▼                                         ▼
        Parallel Hash Join                        Parallel Hash Join
        (Worker 1)                                (Worker 2)
              │                                         │
        Parallel Seq Scan                         Parallel Seq Scan
```

- **`Gather`**: Merges result tuples from background workers back to the main backend process without preserving order.
- **`Gather Merge`**: Preserves sorted order while merging pre-sorted worker streams.
- **`Parallel Seq Scan`**: Workers coordinate to divide 8KB disk pages and scan distinct page ranges concurrently.

---

## 3. Configuration & Memory Guardrails

```sql
-- Number of worker processes allocated per Gather node (default: 2)
SET max_parallel_workers_per_gather = 4;

-- Total parallel workers across entire cluster (default: 8)
SET max_parallel_workers = 8;
```

> **Warning**: Each parallel worker allocates its own independent `work_mem` buffer. If `work_mem = 64MB` and a query runs 4 parallel workers doing a hash join, the query will consume $4 \times 64\text{MB} = 256\text{MB}$ of RAM.
