# Lab 16.1: Bad Planner Estimates & Correlated Column Skew

## 1. Initial State
PostgreSQL 18.6 instance with standard `work_mem = 4MB`. A vehicle registry table contains 500,000 car records with correlated `make` and `model` columns.

## 2. Dataset Setup
```sql
CREATE TABLE vehicles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    vin VARCHAR(32) NOT NULL,
    owner_id INT NOT NULL
);

-- Seed 500,000 rows where make and model are strongly correlated
INSERT INTO vehicles (make, model, vin, owner_id)
SELECT
    'Toyota', 'Corolla', md5(random()::text), (random()*100000)::int
FROM generate_series(1, 200000);

INSERT INTO vehicles (make, model, vin, owner_id)
SELECT
    'Honda', 'Civic', md5(random()::text), (random()*100000)::int
FROM generate_series(1, 200000);

INSERT INTO vehicles (make, model, vin, owner_id)
SELECT
    'Ford', 'F-150', md5(random()::text), (random()*100000)::int
FROM generate_series(1, 100000);

ANALYZE vehicles;
```

---

## 3. Problem & Initial Plan Observation

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM vehicles WHERE make = 'Toyota' AND model = 'Corolla';
```

### Initial Plan Output:
```
Seq Scan on vehicles  (cost=0.00..10986.00 rows=80000 width=74) (actual time=0.038..28.450 rows=200000 loops=1)
  Filter: ((make = 'Toyota') AND (model = 'Corolla'))
  Buffers: shared hit=3486
Planning Time: 0.092 ms
Execution Time: 32.140 ms
```

**The Skew**: The planner estimated `rows=80000`, but actual rows was `200000` (a $2.5\times$ error caused by assuming `make` and `model` are independent). When joined with another table, this causes the planner to pick a slow Nested Loop join.

---

## 4. Fix & Remediation: Extended Statistics

```sql
-- Create multi-column extended statistics
CREATE STATISTICS stat_vehicles_make_model (dependencies, mcv)
    ON make, model FROM vehicles;

ANALYZE vehicles;
```

---

## 5. After Measurement

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM vehicles WHERE make = 'Toyota' AND model = 'Corolla';
```

### Output After Fix:
```
Seq Scan on vehicles  (cost=0.00..10986.00 rows=200000 width=74) (actual time=0.035..27.810 rows=200000 loops=1)
  Filter: ((make = 'Toyota') AND (model = 'Corolla'))
  Buffers: shared hit=3486
Planning Time: 0.115 ms
Execution Time: 31.890 ms
```
*Estimated rows now exactly matches Actual rows (`rows=200000`), allowing downstream join planners to pick the optimal Hash Join.*
