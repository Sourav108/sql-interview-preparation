# Module 23: Database Integration Testing & Validation

## Learning Objectives

By the end of this module, you will be able to:
- Test SQL queries, constraints, and migrations against real **PostgreSQL 18.6** using **Testcontainers**.
- Explain why in-memory databases (like H2) fail to detect real-world PostgreSQL concurrency bugs, MVCC behavior, and dialect-specific features.
- Write automated tests verifying database constraints, foreign key cascades, and trigger invariants.
- Build multi-threaded integration tests to validate transaction isolation and race condition handling.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-testing-with-testcontainers.md](01-testing-with-testcontainers.md) | Testcontainers PostgreSQL lifecycle, H2 anti-pattern, migration testing |
| [02-testing-constraints-and-concurrency.md](02-testing-constraints-and-concurrency.md) | Writing automated tests for race conditions, constraints, and deadlocks |
