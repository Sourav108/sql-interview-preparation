# Module 19: Isolation Levels, MVCC & Locking Internals

## Learning Objectives

By the end of this module, you will be able to:
- Compare ANSI SQL Isolation Levels (`READ COMMITTED`, `REPEATABLE READ`, `SERIALIZABLE`) and identify concurrency phenomena (Dirty Reads, Non-Repeatable Reads, Phantoms, Lost Updates, Write Skew).
- Explain PostgreSQL's Multi-Version Concurrency Control (MVCC) internals: `xmin`, `xmax`, tuple visibility rules, and Heap-Only Tuple (HOT) updates.
- Employ explicit row-level locking (`FOR UPDATE`, `FOR SHARE`, `SKIP LOCKED`, `NOWAIT`) to build high-throughput job queues.
- Reproduce, debug, and resolve deadlocks and lock contention bottlenecks in hands-on labs.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-isolation-levels-and-phenomena.md](01-isolation-levels-and-phenomena.md) | Standard isolation levels, PostgreSQL implementation, concurrency anomalies |
| [02-mvcc-internals.md](02-mvcc-internals.md) | xmin, xmax, snapshot horizons, tuple visibility, dead tuples & autovacuum |
| [03-explicit-locking-and-skip-locked.md](03-explicit-locking-and-skip-locked.md) | Row locks, table lock hierarchy, `FOR UPDATE SKIP LOCKED` queues |
| [labs/lab-01-deadlock.md](labs/lab-01-deadlock.md) | Lab: Inducing and resolving PostgreSQL deadlock `40P01` |
| [labs/lab-02-lock-contention.md](labs/lab-02-lock-contention.md) | Lab: Row-level lock contention diagnosis via `pg_locks` |
| [labs/lab-03-lost-update.md](labs/lab-03-lost-update.md) | Lab: Simulating Lost Updates under READ COMMITTED & 3 remediations |
