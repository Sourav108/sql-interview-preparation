# 02. Declarative Table Partitioning & Partition Pruning

## 1. Why Partition Tables?

When a single table reaches 100M+ rows (100GB+ on disk), even B-Tree indexes become too large to fit in `shared_buffers` RAM.

**Table Partitioning** splits one logical table into smaller, independent physical tables (partitions) while presenting a single unified table interface to queries.

```
                              Logical Table: "metrics"
                                         │
        ┌────────────────────────────────┼────────────────────────────────┐
        ▼                                ▼                                ▼
 Partition: metrics_2026_01      Partition: metrics_2026_02      Partition: metrics_2026_03
 (Jan 2026 data only)            (Feb 2026 data only)            (Mar 2026 data only)
 Independent B-Tree Index        Independent B-Tree Index        Independent B-Tree Index
```

### Key Advantages:
1. **Partition Pruning**: Queries filtering by date scan *only* the matching physical sub-table and completely skip all other partitions.
2. **Instant Bulk Deletion**: Dropping an old month takes $0\text{ms}$ via `DROP TABLE metrics_2024_01;` (instant file unlinking without generating dead tuples or WAL overhead).

---

## 2. Declarative Range Partitioning Example

```sql
-- 1. Create Partitioned Parent Table
CREATE TABLE telemetry_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    device_id INT NOT NULL,
    temperature NUMERIC(5, 2) NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id, recorded_at) -- Partition key MUST be part of primary key!
) PARTITION BY RANGE (recorded_at);

-- 2. Create Monthly Physical Partitions
CREATE TABLE telemetry_2026_08 PARTITION OF telemetry_events
    FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00');

CREATE TABLE telemetry_2026_09 PARTITION OF telemetry_events
    FOR VALUES FROM ('2026-09-01 00:00:00+00') TO ('2026-10-01 00:00:00+00');

CREATE TABLE telemetry_default PARTITION OF telemetry_events DEFAULT;
```

---

## 3. Partition Pruning in Action

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM telemetry_events
WHERE recorded_at >= '2026-09-15 00:00:00+00'
  AND recorded_at <  '2026-09-16 00:00:00+00';
```

### Execution Plan Output:
```
Seq Scan on telemetry_2026_09 telemetry_events  (cost=0.00..28.50 rows=10 width=28)
-- Notice: telemetry_2026_08 and telemetry_default are completely ignored!
```
