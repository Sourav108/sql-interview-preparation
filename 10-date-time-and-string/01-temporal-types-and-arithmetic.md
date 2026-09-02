# 01. Temporal Types, Arithmetic, and Time Zones

## 1. Temporal Data Type Reference

| Type | Storage | Contains | Use Case |
| :--- | :--- | :--- | :--- |
| `DATE` | 4 bytes | Calendar date only | Birthdates, settlement dates, calendar days |
| `TIME` | 8 bytes | Time of day (no date) | Store hours, shift times |
| `TIMESTAMP` | 8 bytes | Date + time, **no time zone** | Avoid for event timestamps — ambiguous across DST |
| `TIMESTAMPTZ` | 8 bytes | Date + time, **UTC-normalized** | ✅ Preferred for all event timestamps |
| `INTERVAL` | 16 bytes | Duration / span | Add/subtract from dates; express periods |

> **[PostgreSQL Specific]**: `TIMESTAMPTZ` stores values as UTC internally. On read, PostgreSQL converts to the current session's `TimeZone` setting. This makes it unambiguous across DST transitions and server migrations.

```sql
-- ❌ TIMESTAMP: no time zone context — ambiguous after DST or server move
created_at TIMESTAMP DEFAULT NOW()

-- ✅ TIMESTAMPTZ: always stored as UTC, displayed in session time zone
created_at TIMESTAMPTZ DEFAULT NOW()

-- Check session time zone
SHOW TimeZone;
SET TimeZone = 'Asia/Kolkata';
```

---

## 2. Date Arithmetic

```sql
-- [Standard SQL / PostgreSQL]
-- Add/subtract intervals
SELECT NOW() + INTERVAL '30 days';           -- 30 days from now
SELECT NOW() - INTERVAL '1 year 3 months';   -- 15 months ago
SELECT '2026-09-02'::DATE + 7;               -- [PostgreSQL] add integer days to DATE → DATE
SELECT '2026-09-02'::DATE - '2026-01-01'::DATE; -- difference in integer days: 244

-- Age between two timestamps
SELECT AGE('2026-09-02'::DATE, '1995-03-15'::DATE);
-- → 31 years 5 months 18 days

-- Extracting epoch seconds (useful for duration calculations)
SELECT EXTRACT(EPOCH FROM (NOW() - '2026-01-01 00:00:00+00'));
-- → elapsed seconds since Jan 1 2026
```

---

## 3. DATE_TRUNC — Truncate to a Calendar Unit

```sql
-- [PostgreSQL Specific] DATE_TRUNC(unit, timestamp)
SELECT DATE_TRUNC('year',    NOW());   -- → 2026-01-01 00:00:00+05:30
SELECT DATE_TRUNC('quarter', NOW());   -- → 2026-07-01 00:00:00+05:30
SELECT DATE_TRUNC('month',   NOW());   -- → 2026-09-01 00:00:00+05:30
SELECT DATE_TRUNC('week',    NOW());   -- → Monday of current week
SELECT DATE_TRUNC('day',     NOW());   -- → 2026-09-02 00:00:00+05:30
SELECT DATE_TRUNC('hour',    NOW());   -- → 2026-09-02 15:00:00+05:30

-- Critical usage: grouping by month
SELECT
    DATE_TRUNC('month', placed_at)::DATE AS month,
    COUNT(*)                              AS orders,
    SUM(total)                            AS revenue
FROM orders
WHERE status = 'DELIVERED'
GROUP BY DATE_TRUNC('month', placed_at)
ORDER BY month;
```

---

## 4. EXTRACT — Pull a Single Component

```sql
-- [Standard SQL]
SELECT EXTRACT(YEAR   FROM NOW());   -- 2026
SELECT EXTRACT(MONTH  FROM NOW());   -- 9
SELECT EXTRACT(DAY    FROM NOW());   -- 2
SELECT EXTRACT(HOUR   FROM NOW());   -- 15 (session time zone)
SELECT EXTRACT(DOW    FROM NOW());   -- 0=Sunday … 6=Saturday
SELECT EXTRACT(EPOCH  FROM NOW());   -- Unix timestamp (seconds since 1970-01-01 UTC)

-- [PostgreSQL Specific shorthand]
SELECT DATE_PART('year', NOW());     -- same as EXTRACT YEAR, returns float8
```

---

## 5. Sargable Date Predicates

```sql
-- ❌ NON-SARGABLE: function on indexed column prevents B-Tree seek
WHERE EXTRACT(YEAR FROM placed_at) = 2026
WHERE DATE_TRUNC('month', placed_at) = '2026-09-01'
WHERE DATE(placed_at) = '2026-09-02'

-- ✅ SARGABLE: range bounds preserve index seek
WHERE placed_at >= '2026-01-01 00:00:00+00'
  AND placed_at <  '2027-01-01 00:00:00+00'

WHERE placed_at >= '2026-09-01 00:00:00+00'
  AND placed_at <  '2026-10-01 00:00:00+00'

-- Rule: push the function to the literal constant side, keep the column clean
-- [PostgreSQL Specific] Alternative: create an expression index
CREATE INDEX idx_orders_year ON orders (EXTRACT(YEAR FROM placed_at));
-- Then this IS sargable:
WHERE EXTRACT(YEAR FROM placed_at) = 2026;
```

---

## 6. generate_series — Gap Filling

A common analytics requirement: show every date in a range even when no data exists for some dates.

```sql
-- [PostgreSQL Specific] generate_series for date gap-filling
WITH date_spine AS (
    SELECT generate_series(
        '2026-08-01'::DATE,
        '2026-09-02'::DATE,
        '1 day'::INTERVAL
    )::DATE AS day
)
SELECT
    ds.day,
    COALESCE(COUNT(o.id), 0)    AS order_count,
    COALESCE(SUM(o.total), 0)   AS daily_revenue
FROM date_spine ds
LEFT JOIN orders o
    ON  o.placed_at::DATE = ds.day
    AND o.status = 'DELIVERED'
GROUP BY ds.day
ORDER BY ds.day;
-- Every calendar day appears, with 0/0 for days with no delivered orders
```

---

## 7. Interval Math for Rolling Windows

```sql
-- Orders placed in the last 30 days
SELECT id, placed_at, total
FROM orders
WHERE placed_at >= NOW() - INTERVAL '30 days';

-- Monthly active users: customers who ordered in any of the last 3 months
SELECT
    customer_id,
    COUNT(DISTINCT DATE_TRUNC('month', placed_at)) AS active_months
FROM orders
WHERE placed_at >= DATE_TRUNC('month', NOW()) - INTERVAL '2 months'
  AND placed_at <  DATE_TRUNC('month', NOW()) + INTERVAL '1 month'
GROUP BY customer_id
HAVING COUNT(DISTINCT DATE_TRUNC('month', placed_at)) >= 2;
```

---

## 8. Interview Questions

**Q1: Why use TIMESTAMPTZ over TIMESTAMP for event timestamps?**
`TIMESTAMP` stores no time zone information — it records a "wall clock time" that becomes ambiguous when the server moves data centers, when DST transitions occur, or when data is shared across time zones. `TIMESTAMPTZ` normalizes all values to UTC on write, storing them unambiguously. Reads convert to the session's configured time zone. The 8-byte storage cost is identical. Always use `TIMESTAMPTZ` for event timestamps in any system that may operate across time zones.

**Q2: Why is `WHERE DATE_TRUNC('month', placed_at) = '2026-09-01'` dangerous for performance?**
It wraps the indexed column `placed_at` in a function, preventing the B-Tree index from performing a direct seek. The database must apply `DATE_TRUNC` to every row and compare the result — a full sequential scan. The sargable equivalent is an explicit range: `WHERE placed_at >= '2026-09-01' AND placed_at < '2026-10-01'`, which allows the index to seek to the first matching leaf page and scan only the relevant range.

**Q3: How do you show daily revenue for every day in a month, including days with zero orders?**
Use `generate_series` to create a complete date spine, then `LEFT JOIN` to actual orders and `COALESCE` the aggregates to zero: `SELECT ds.day, COALESCE(SUM(o.total), 0) FROM generate_series(...) ds LEFT JOIN orders o ON o.placed_at::DATE = ds.day GROUP BY ds.day`. Without the date spine, days with no orders are omitted from the result.

---

## 9. Further Reading
- [PostgreSQL 18 Documentation: Date/Time Types](https://www.postgresql.org/docs/18/datatype-datetime.html)
- [PostgreSQL 18 Documentation: Date/Time Functions](https://www.postgresql.org/docs/18/functions-datetime.html)
