# Lab 20.1: Table Bloat & Autovacuum Tuning

## 1. Problem
A high-frequency update table (`account_balances`) contains only 10,000 active accounts, but disk size has exploded from 1MB to over 500MB, causing queries to slow down.

---

## 2. Simulation Setup

```sql
CREATE TABLE account_balances (
    id INT PRIMARY KEY,
    balance NUMERIC(10,2) NOT NULL
);

INSERT INTO account_balances SELECT g, 100.00 FROM generate_series(1, 10000) g;

-- Disable autovacuum temporarily to induce bloat
ALTER TABLE account_balances SET (autovacuum_enabled = false);

-- Simulate 50 update rounds (generates 500,000 dead MVCC tuples!)
DO $$
BEGIN
    FOR i IN 1..50 LOOP
        UPDATE account_balances SET balance = balance + 1;
    END LOOP;
END $$;
```

---

## 3. Investigating Bloat via `pg_stat_user_tables`

```sql
SELECT
    relname,
    n_live_tup  AS live_rows,
    n_dead_tup  AS dead_rows,
    pg_size_pretty(pg_relation_size(relid)) AS table_disk_size
FROM pg_stat_user_tables
WHERE relname = 'account_balances';
```

### Observation:
- `live_rows`: 10,000
- `dead_rows`: 500,000
- `table_disk_size`: `38 MB` (for only 10,000 rows!)

---

## 4. Remediation & Autovacuum Tuning

### Immediate Space Reclamation:
```sql
-- 1. Full table rewrite to physically compact pages on disk
VACUUM FULL account_balances;

-- Verify size: table drops from 38MB to 440KB!
```

### Long-Term Prevention: Aggressive Table Autovacuum Settings
```sql
ALTER TABLE account_balances SET (
    autovacuum_enabled = true,
    autovacuum_vacuum_scale_factor = 0.05, -- Vacuum when 5% dead tuples accumulate (default 20%)
    autovacuum_vacuum_cost_limit = 1000    -- Increase background I/O allowance
);
```
