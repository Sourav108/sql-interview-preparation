# Lab 19.1: Deadlock Reproduction & Resolution

## 1. Initial State
Two concurrent client sessions connected to PostgreSQL 18.6 with `deadlock_timeout = '1s'`.

## 2. Dataset Setup
```sql
CREATE TABLE accounts (
    id INT PRIMARY KEY,
    owner VARCHAR(50) NOT NULL,
    balance NUMERIC(10,2) NOT NULL
);

INSERT INTO accounts VALUES (1, 'Alice', 1000.00), (2, 'Bob', 1000.00);
```

---

## 3. Step-by-Step Deadlock Reproduction

Execute the following commands across two distinct `psql` terminal sessions:

| Time | Session 1 (Txn A: Transfer $100 from Alice to Bob) | Session 2 (Txn B: Transfer $50 from Bob to Alice) |
| :-: | :--- | :--- |
| **$T_1$** | `BEGIN;` | `BEGIN;` |
| **$T_2$** | `UPDATE accounts SET balance = balance - 100 WHERE id = 1;`<br>*(Acquires exclusive row lock on id=1)* | |
| **$T_3$** | | `UPDATE accounts SET balance = balance - 50 WHERE id = 2;`<br>*(Acquires exclusive row lock on id=2)* |
| **$T_4$** | `UPDATE accounts SET balance = balance + 100 WHERE id = 2;`<br>*(Blocks waiting for Session 2 to release id=2...)* | |
| **$T_5$** | | `UPDATE accounts SET balance = balance + 50 WHERE id = 1;`<br>*(Cycle formed! Both sessions wait on each other)* |
| **$T_6$** | | **ERROR 40P01 (deadlock detected)**<br>`DETAIL: Process 4125 waits for ExclusiveLock on tuple (0,1) of relation accounts; blocked by process 4110.` |

---

## 4. Root Cause & Architectural Resolution

### Root Cause
Asymmetric resource acquisition ordering (Session 1 locked `1 → 2`; Session 2 locked `2 → 1`).

### Remediation Protocol: Deterministic Global Lock Ordering
Always acquire locks on multiple resources in a consistent, globally sorted order (e.g. by Primary Key ascending):

```sql
-- In both Session 1 and Session 2 application code:
-- Before updating, lock all participating account IDs in sorted order:
SELECT * FROM accounts WHERE id IN (1, 2) ORDER BY id FOR UPDATE;
-- Both sessions will now attempt to acquire lock on ID 1 first.
-- Session 2 will wait politely on ID 1 before touching ID 2, eliminating deadlocks!
```
