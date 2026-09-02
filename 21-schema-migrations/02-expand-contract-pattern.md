# 02. The Expand / Contract (Parallel Run) Migration Pattern

## 1. The Core Architectural Philosophy

> **Never introduce a breaking schema change in a single release.**
> Backward compatibility ensures old application versions continue functioning smoothly during rolling deployments.

```
Phase 1: Expand                Phase 2: Migrate / Dual Write         Phase 3: Contract
─────────────────             ─────────────────────────────         ─────────────────
Add new column `full_name`     App writes to both `first_name`       App reads only `full_name`
(keep `first_name`, `last_name`) and `full_name`. Backfill past data. Drop old columns.
```

---

## 2. Walkthrough: Renaming a Column Without Downtime

Goal: Rename `users.phone_number` to `users.phone_e164` in a 100-million row table with zero downtime.

### Step 1: Expand (Release 1 - Database Migration)
```sql
ALTER TABLE users ADD COLUMN phone_e164 VARCHAR(32);
```

### Step 2: Dual-Write (Release 2 - Application Deployment)
Application reads from `phone_number` (fallback `phone_e164`), but writes to **both** columns on every user update.

### Step 3: Backfill Past Data in Micro-Batches
```sql
-- Backfill in small chunks of 5,000 rows to prevent WAL spikes and lock contention
UPDATE users
SET phone_e164 = phone_number
WHERE id BETWEEN :start_id AND :end_id
  AND phone_e164 IS NULL;
```

### Step 4: Switch Reads (Release 3 - Application Deployment)
Application code is updated to read and write **exclusively** to `phone_e164`.

### Step 5: Contract (Release 4 - Database Migration)
```sql
ALTER TABLE users DROP COLUMN phone_number;
```
