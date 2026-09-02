# Module 18: Transactions & Concurrency Fundamentals

## Learning Objectives

By the end of this module, you will be able to:
- Define the ACID guarantees and their database-engine implementation mechanics.
- Control transaction boundaries using `BEGIN`, `COMMIT`, `ROLLBACK`, and `SAVEPOINT`.
- Explain Write-Ahead Logging (WAL) and crash-recovery protocols (ARIES).
- Model and implement a bulletproof double-entry banking ledger with invariant checks.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-acid-properties-and-wal.md](01-acid-properties-and-wal.md) | Atomicity, Consistency, Isolation, Durability, WAL mechanics |
| [02-transaction-control-and-savepoints.md](02-transaction-control-and-savepoints.md) | BEGIN, COMMIT, ROLLBACK, SAVEPOINT, partial rollbacks |
| [03-double-entry-ledger-case.md](03-double-entry-ledger-case.md) | Complete double-entry accounting schema with transaction safety |
