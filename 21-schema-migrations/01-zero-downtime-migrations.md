# 01. Zero-Downtime Schema Migrations and Lock Timeouts

## 1. Why Migrations Cause Production Outages

Running naive DDL like `ALTER TABLE orders ADD COLUMN is_vip BOOLEAN DEFAULT false;` or `CREATE INDEX idx_orders_customer ON orders (customer_id);` acquires an **`ACCESS EXCLUSIVE`** table lock.

```
Long-Running Analytical Query (PID 100)
    │
    ▼ (Holds AccessShareLock)
Migration DDL: ALTER TABLE orders ... (PID 200)
    │
    ▼ (Waits for PID 100 to finish; queues behind it requesting AccessExclusiveLock)
Active Web Traffic: SELECT * FROM orders ... (PID 300, 301, 302, 303...)
    │
    ▼ (BLOCKED behind PID 200!)
Connection Pool Exhaustion → Entire API goes down with HTTP 504 Gateway Timeouts!
```

---

## 2. Guardrail 1: The Lock Timeout Invariant

**Rule**: *Every single migration script in production must set a strict `lock_timeout`.*

```sql
-- Abort immediately if the migration cannot acquire its table lock within 3 seconds:
SET lock_timeout = '3s';
SET statement_timeout = '30s';

-- Run DDL
ALTER TABLE users ADD COLUMN phone_verified BOOLEAN;
```
If active queries block the DDL, the migration fails fast and rolls back, saving production from an outage.

---

## 3. Guardrail 2: `CREATE INDEX CONCURRENTLY`

A standard `CREATE INDEX` locks the table against all writes for the entire duration of the build.

```sql
-- Safe production index build (DOES NOT LOCK WRITES):
CREATE INDEX CONCURRENTLY idx_users_phone ON users (phone);
```

### How `CONCURRENTLY` Works:
1. **Pass 1**: Scans table and creates initial B-tree structure.
2. **Pass 2**: Waits for concurrent transactions to finish, then catches up on modifications made during Pass 1.
3. **Constraint**: `CREATE INDEX CONCURRENTLY` cannot run inside an active `BEGIN ... COMMIT` transaction block.
