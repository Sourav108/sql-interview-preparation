# Module 15: Query Execution Engine Internals

## Learning Objectives

By the end of this module, you will be able to:
- Trace the lifecycle of a SQL query through the PostgreSQL engine: Parser $\to$ Analyzer $\to$ Rewriter $\to$ Planner $\to$ Executor.
- Explain how the PostgreSQL cost model calculates startup cost and total cost.
- Compare the three fundamental join algorithms: **Nested Loop Join**, **Hash Join**, and **Merge Join**.
- Identify when parallel query execution is triggered and its worker memory allocations.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-query-lifecycle-and-cost-model.md](01-query-lifecycle-and-cost-model.md) | Parser to Executor pipeline, cost units (`seq_page_cost`, `random_page_cost`) |
| [02-join-algorithms-deep-dive.md](02-join-algorithms-deep-dive.md) | Nested Loop vs Hash Join vs Merge Join mechanics & memory limits |
| [03-parallel-query-execution.md](03-parallel-query-execution.md) | Parallel scans, parallel hash joins, `max_parallel_workers_per_gather` |
