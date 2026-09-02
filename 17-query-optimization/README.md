# Module 17: Query Optimization & Performance Engineering

## Learning Objectives

By the end of this module, you will be able to:
- Execute the evidence-driven query optimization protocol: Capture $\to$ Analyze $\to$ Hypothesize $\to$ Rewrite $\to$ Benchmark.
- Eliminate correlated subquery loops via set-based rewriting.
- Implement $O(\log N)$ **Keyset / Cursor Pagination** to replace linear $O(N)$ high-OFFSET reads.
- Optimize sort and join memory footprint using session-level `work_mem` tuning.
- Benchmark and verify performance improvements using buffer page read deltas.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-optimization-methodology.md](01-optimization-methodology.md) | The 8-step evidence-driven tuning protocol |
| [02-pagination-at-scale.md](02-pagination-at-scale.md) | OFFSET / LIMIT degradation vs Keyset pagination |
| [labs/lab-01-slow-query-rewrite.md](labs/lab-01-slow-query-rewrite.md) | Lab: Rewriting correlated subquery loops into Hash Semi-Joins |
| [labs/lab-02-deep-offset-pagination.md](labs/lab-02-deep-offset-pagination.md) | Lab: Benchmarking OFFSET 500,000 vs Keyset Seek (4000x speedup) |
