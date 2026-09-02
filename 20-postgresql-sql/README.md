# Module 20: PostgreSQL Advanced SQL & Internals

## Learning Objectives

By the end of this module, you will be able to:
- Leverage native PostgreSQL data structures: **`JSONB`** with GIN indexing, **Arrays**, and **ENUMs**.
- Implement declarative table partitioning (Range, List, Hash) and verify partition pruning.
- Configure Generated Columns (`STORED`) and Identity columns (`GENERATED ALWAYS AS IDENTITY`).
- Query PostgreSQL system catalogs (`pg_stat_activity`, `pg_stat_user_tables`, `pg_statio_user_tables`) for operational insights.
- Execute hands-on table bloat and autovacuum tuning labs.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-jsonb-and-arrays.md](01-jsonb-and-arrays.md) | JSONB operators (`@>`, `?`, `->`, `->>`), GIN indexing, Arrays |
| [02-table-partitioning.md](02-table-partitioning.md) | Declarative Range, List, and Hash partitioning with partition pruning |
| [03-system-views-and-catalogs.md](03-system-views-and-catalogs.md) | Querying `pg_stat_activity`, table bloat queries, index usage metrics |
| [labs/lab-01-bloat-and-vacuum.md](labs/lab-01-bloat-and-vacuum.md) | Lab: Simulating MVCC dead tuple bloat & autovacuum tuning |
