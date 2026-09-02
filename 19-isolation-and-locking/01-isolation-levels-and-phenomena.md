# 01. ANSI SQL Isolation Levels and Concurrency Phenomena

## 1. Concurrency Anomalies Defined

When multiple transactions execute concurrently without strict isolation, five classic anomalies can arise:

1. **Dirty Read**: Transaction A reads modifications made by Transaction B that have not yet been committed. If B rolls back, A acted on invalid data.
2. **Non-Repeatable Read (Fuzzy Read)**: Transaction A reads row $X$. Transaction B updates/deletes row $X$ and commits. Transaction A re-reads row $X$ and finds its values changed.
3. **Phantom Read**: Transaction A queries a range of rows matching a predicate (e.g. `WHERE salary > 100000`). Transaction B inserts a *new* row matching that predicate and commits. Transaction A repeats the query and sees a new "phantom" row.
4. **Lost Update**: Transactions A and B both read balance = ₹100. Both calculate new balance (+₹50 and +₹20) and write back ₹150 and ₹120. One update silently overwrites the other.
5. **Write Skew**: In a hospital on-call rota requiring at least 1 doctor on duty, Dr. A and Dr. B both query active doctors (count=2), and both concurrently take leave, leaving 0 doctors on duty.

---

## 2. Standard Isolation Levels vs. PostgreSQL Reality

| ANSI SQL Level | Dirty Read | Non-Repeatable Read | Phantom Read | PostgreSQL Implementation |
| :--- | :---: | :---: | :---: | :--- |
| **`READ UNCOMMITTED`** | Allowed | Allowed | Allowed | **Behaves as `READ COMMITTED`** in PostgreSQL (no dirty reads ever) |
| **`READ COMMITTED`** *(Default)* | ❌ Prevented | Allowed | Allowed | New snapshot generated at the start of **each individual statement** |
| **`REPEATABLE READ`** | ❌ Prevented | ❌ Prevented | ❌ Prevented *(In PG)* | Single snapshot generated at the start of the **first statement in transaction** |
| **`SERIALIZABLE`** (SSI) | ❌ Prevented | ❌ Prevented | ❌ Prevented | Uses Serializable Snapshot Isolation (SSI) to detect and abort write skew |

---

## 3. How to Set Isolation Level

```sql
-- Per transaction:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Per session:
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

> **Rule for `REPEATABLE READ` & `SERIALIZABLE`**: Applications must implement retry loops! If a conflict occurs, PostgreSQL raises error code `40001 (serialization_failure)`:
> `ERROR: could not serialize access due to concurrent update`
