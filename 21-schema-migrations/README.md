# Module 21: Zero-Downtime Schema Migrations & Safe DDL

## Learning Objectives

By the end of this module, you will be able to:
- Execute zero-downtime schema changes on high-traffic production databases.
- Implement the 4-phase **Expand / Contract (Parallel Run)** migration pattern.
- Build indexes on multi-million row tables safely using `CREATE INDEX CONCURRENTLY`.
- Guard against migration lock queues using explicit `lock_timeout` settings.
- Add `NOT NULL` columns, rename columns, and change column data types without table locks.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-zero-downtime-migrations.md](01-zero-downtime-migrations.md) | Lock levels, table rewrites, `lock_timeout`, `CREATE INDEX CONCURRENTLY` |
| [02-expand-contract-pattern.md](02-expand-contract-pattern.md) | Expand $\to$ Dual Write $\to$ Backfill $\to$ Contract workflow |
| [03-safe-ddl-runbook.md](03-safe-ddl-runbook.md) | Safe patterns for renaming columns, adding NOT NULL, changing types |
