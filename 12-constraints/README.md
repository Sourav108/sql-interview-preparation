# Module 12: Integrity Constraints

## Learning Objectives

By the end of this module, you will be able to:
- Enforce database-level data integrity using `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `NOT NULL`, and `CHECK`.
- Configure foreign key cascade rules (`RESTRICT`, `CASCADE`, `SET NULL`, `SET DEFAULT`, `NO ACTION`).
- Implement PostgreSQL exclusion constraints (`EXCLUDE USING gist`) for non-overlapping ranges (e.g. room bookings, temporal validity).
- Defend the architectural principle: *"Put correctness guarantees as close to the data as practical."*
- Compare database constraints vs. application-layer validation and explain why production systems need both.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-constraints-and-integrity.md](01-constraints-and-integrity.md) | Standard constraints, CHECK predicates, cascading foreign keys |
| [02-exclusion-constraints.md](02-exclusion-constraints.md) | Temporal & geometric constraints with `EXCLUDE USING gist` |
| [03-database-vs-app-validation.md](03-database-vs-app-validation.md) | Concurrency race conditions, defense in depth, architectural trade-offs |
