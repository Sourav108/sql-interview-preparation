# Cheatsheet 04: Indexing Internals & EXPLAIN ANALYZE

## ⚡ 1. Composite Indexing Rules

1. **Leftmost Prefix Rule**: Multi-column index `(A, B, C)` can seek `(A)`, `(A, B)`, and `(A, B, C)`. It CANNOT seek `(B)` or `(C)`.
2. **Equality Before Range**: `(status, created_at)` is superior to `(created_at, status)` for queries filtering `WHERE status = 'ACTIVE' AND created_at >= ?`.
3. **Covering Index (`INCLUDE`)**: Store non-search payload columns in index leaf pages to enable heap-free **Index-Only Scans**.

---

## ⚡ 2. Reading `EXPLAIN (ANALYZE, BUFFERS)`

- **Estimated Cost $\ne$ Wall-Clock Time**: Cost is an abstract planner formula; `actual time` is real elapsed milliseconds.
- **Loops Multiplier**: $\text{Total Rows} = \text{actual rows} \times \text{loops}$.
- **Buffer Hits vs Reads**: `hit` = served from RAM (`shared_buffers`), `read` = disk I/O.
- **Disk Spills**: `external merge Disk` means sort/hash exceeded `work_mem` and spilled to temp files.
