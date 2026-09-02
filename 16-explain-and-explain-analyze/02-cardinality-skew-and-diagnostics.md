# 02. Cardinality Skew and Extended Statistics

## 1. Why Bad Estimates Destroy Performance

The PostgreSQL query planner relies on table statistics in `pg_statistic` (populated by `ANALYZE`) to estimate how many rows will match a filter.

When the planner makes a bad cardinality estimate, it picks disastrous execution strategies:
- If estimated rows = 1 but actual rows = 50,000: Planner chooses a **Nested Loop Join**, executing 50,000 index lookups instead of 1 fast **Hash Join**.
- If estimated rows = 1,000,000 but actual rows = 1: Planner allocates massive memory buffers and performs full table scans for a point lookup.

---

## 2. Root Causes of Estimation Skew

1. **Stale Statistics**: High-volume inserts or updates occurred without `ANALYZE` running to refresh `pg_statistic`.
2. **Correlated Columns**: PostgreSQL by default assumes that columns in the same table are completely independent.
   - Example: `WHERE make = 'Audi' AND model = 'A4'`.
   - The planner multiplies $P(\text{Audi}) \times P(\text{A4})$ ($0.05 \times 0.005 = 0.00025$), estimating 25 rows instead of the actual 5,000!

---

## 3. The Fix: Extended Statistics (`CREATE STATISTICS`)

PostgreSQL allows creating multivariate statistics to capture column correlation and dependencies.

```sql
-- Create multivariate statistics capturing dependency between make and model
CREATE STATISTICS stats_cars_make_model (dependencies, mcv)
    ON make, model FROM cars;

-- Refresh statistics immediately
ANALYZE cars;
```

Now the planner inspects the joint Most Common Values (`mcv`) table and estimates actual row counts with $>99\%$ accuracy.
