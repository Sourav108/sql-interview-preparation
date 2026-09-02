# 02. Transaction Control & SAVEPOINTs

## 1. Transaction Control Syntax

```sql
-- Start an explicit transaction block
BEGIN;  -- or START TRANSACTION;

-- Execute operations
UPDATE accounts SET balance = balance - 100.00 WHERE id = 1;
UPDATE accounts SET balance = balance + 100.00 WHERE id = 2;

-- Permanently record all modifications
COMMIT;
```

If an error occurs or business validation fails:
```sql
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE id = 1;

-- Failure condition detected
ROLLBACK; -- Undoes all modifications since BEGIN
```

---

## 2. SAVEPOINTs: Partial Rollbacks

A `SAVEPOINT` creates a nested rollback marker within an ongoing transaction block, allowing partial failure recovery without aborting the entire transaction.

```sql
BEGIN;

-- 1. Deduct primary order payment
UPDATE accounts SET balance = balance - 500.00 WHERE id = 1;

-- 2. Create checkpoint before optional promotional reward
SAVEPOINT before_promo_credit;

-- 3. Attempt promotional credit to partner account
UPDATE partner_accounts SET credits = credits + 50 WHERE partner_id = 999;
-- If partner account does not exist or fails a CHECK constraint:

-- 4. Roll back ONLY the partner credit, preserving the primary order deduction
ROLLBACK TO SAVEPOINT before_promo_credit;

-- 5. Commit the primary payment
COMMIT;
```
