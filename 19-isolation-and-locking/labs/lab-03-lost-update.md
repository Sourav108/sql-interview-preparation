# Lab 19.3: Simulating Lost Updates & 3 Remediation Strategies

## 1. Problem: The Classic Lost Update Race Condition

Under default `READ COMMITTED` isolation, when two transactions concurrently read and modify the same balance without locking:

| Time | Session 1 (Deposit $50) | Session 2 (Deposit $20) |
| :-: | :--- | :--- |
| **$T_1$** | `BEGIN;` | `BEGIN;` |
| **$T_2$** | `SELECT balance FROM accounts WHERE id = 1;` $\to \$100$ | `SELECT balance FROM accounts WHERE id = 1;` $\to \$100$ |
| **$T_3$** | In-app compute: $100 + 50 = \$150$ | In-app compute: $100 + 20 = \$120$ |
| **$T_4$** | `UPDATE accounts SET balance = 150 WHERE id = 1;` | |
| **$T_5$** | `COMMIT;` (Balance is now $150) | |
| **$T_6$** | | `UPDATE accounts SET balance = 120 WHERE id = 1;` |
| **$T_7$** | | `COMMIT;` (Balance is now $120!) |

**The Bug**: Session 1's deposit of $50 is completely erased from history! Final balance should be $170, but is $120.

---

## 2. Three Production Remediation Strategies

### Strategy 1: Atomic Database Updates (Preferred)
Push arithmetic calculation directly into the SQL engine:
```sql
UPDATE accounts SET balance = balance + 50 WHERE id = 1;
-- PostgreSQL locks the row during evaluation, ensuring serial execution of increments!
```

### Strategy 2: Pessimistic Locking (`SELECT ... FOR UPDATE`)
Lock the row upon initial read:
```sql
BEGIN;
SELECT balance FROM accounts WHERE id = 1 FOR UPDATE; -- Blocks Session 2
-- Perform application logic
UPDATE accounts SET balance = 150 WHERE id = 1;
COMMIT;
```

### Strategy 3: Optimistic Concurrency Control (OCC with Versioning)
Add a `version` column to the table:
```sql
UPDATE accounts
SET balance = 150, version = version + 1
WHERE id = 1 AND version = :expected_version;

-- If rows_updated == 0: Throw OptimisticLockingFailureException and retry!
```
