# Cheatsheet 05: Transactions, Isolation Levels & MVCC

## ⚡ 1. ANSI Isolation Levels & Concurrency Phenomena

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Serialization Anomaly |
| :--- | :---: | :---: | :---: | :---: |
| **`READ UNCOMMITTED`** *(In PG: Acts as Read Committed)* | Allowed (Standard) | Allowed | Allowed | Allowed |
| **`READ COMMITTED`** *(PG Default)* | ❌ Prevented | Allowed | Allowed | Allowed |
| **`REPEATABLE READ`** | ❌ Prevented | ❌ Prevented | ❌ Prevented *(In PG)* | Allowed (Write Skew) |
| **`SERIALIZABLE`** | ❌ Prevented | ❌ Prevented | ❌ Prevented | ❌ Prevented |

---

## ⚡ 2. PostgreSQL MVCC System Columns

- **`xmin`**: Transaction ID that inserted this tuple version.
- **`xmax`**: Transaction ID that deleted or updated this tuple version (0 if currently alive).
- **MVCC Invariant**: Readers never block writers; writers never block readers.

---

## ⚡ 3. Explicit Row Locking Modes

- `SELECT ... FOR UPDATE`: Exclusive write lock.
- `SELECT ... FOR UPDATE SKIP LOCKED`: Non-blocking high-throughput queue consumption.
- `SELECT ... FOR UPDATE NOWAIT`: Fail-fast lock attempt.
