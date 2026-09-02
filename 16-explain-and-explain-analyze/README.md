# Module 16: EXPLAIN and EXPLAIN ANALYZE

## Learning Objectives

By the end of this module, you will be able to:
- Read and interpret `EXPLAIN (ANALYZE, BUFFERS)` execution plans.
- Distinguish **Estimated Cost** (theoretical model) from **Actual Time** (wall-clock milliseconds).
- Diagnose **Cardinality Estimation Skew** (e.g. estimated 1 row vs actual 50,000 rows).
- Spot expensive plan nodes: memory spills to disk (`external merge Disk`), unexpected sequential scans, and unindexed nested loop joins.
- Execute hands-on lab experiments to remediate stale table statistics and correlated column skews.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-reading-explain-plans.md](01-reading-explain-plans.md) | Syntax, buffers, loops multiplier, estimated cost vs actual time |
| [02-cardinality-skew-and-diagnostics.md](02-cardinality-skew-and-diagnostics.md) | Root causes of planner misestimates, multivariate statistics (`CREATE STATISTICS`) |
| [labs/lab-01-bad-estimates.md](labs/lab-01-bad-estimates.md) | Lab: Inducing and fixing a 1000x cardinality estimation skew |
