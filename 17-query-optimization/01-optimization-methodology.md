# 01. The Evidence-Driven Query Optimization Protocol

## 1. The Core Engineering Rule

> **Never optimize without measurement. Never claim one query is universally faster.**

Performance in relational databases is contextual: it depends on table statistics, data distribution, buffer cache warmth, available RAM (`work_mem`), index layout, and concurrency.

```
       [1] Capture Slow Query (via pg_stat_statements / Slow Query Log)
                      ↓
       [2] Inspect Plan: EXPLAIN (ANALYZE, BUFFERS)
                      ↓
       [3] Identify Exact Bottleneck Node (Seq Scan, Sort Spill, Hash Batching)
                      ↓
       [4] Formulate Testable Hypothesis
                      ↓
       [5] Implement Change (Index, Query Rewrite, or Schema Adjustment)
                      ↓
       [6] Benchmark Before vs. After (Measure Shared Buffer Reads & Execution Time)
                      ↓
       [7] Verify Zero Regression Across Edge Cases
```

---

## 2. The 7 Primary Levers of Query Optimization

1. **Eliminate Unnecessary Work**: Remove `SELECT *`, redundant `DISTINCT`, and unused `JOIN` tables.
2. **Make Predicates Sargable**: Avoid wrapping indexed columns in functions (`LOWER(col)` $\to$ `col ILIKE` or Expression Index).
3. **Filter Pushdown**: Filter rows inside the earliest possible `ON` clause or subquery before multiplying joins.
4. **Targeted Composite Indexes**: Match equality filters first, range filters second, and projection columns via `INCLUDE`.
5. **Set-Based Rewriting**: Convert $O(N)$ row-by-row correlated subqueries into set-based `JOIN` or `EXISTS` operations.
6. **Keyset Pagination**: Replace deep `OFFSET` scanning with indexed cursor seeking.
7. **Memory Tuning (`work_mem`)**: Increase memory for complex analytical queries to prevent disk spills (`SET work_mem = '64MB';`).
