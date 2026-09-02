# Mock Interview Round 3: Query Plan Analysis & Performance Tuning

## 1. Interviewer Prompt
> **Interviewer**: *"Here is an `EXPLAIN (ANALYZE, BUFFERS)` output from a production incident on an orders table with 10 million rows. Walk me through the plan, identify the exact bottleneck, and explain how you would remediate it."*

```
Hash Join  (cost=24512.00..184200.00 rows=15 width=48) (actual time=42.120..1840.450 rows=12 loops=1)
  Hash Cond: (o.customer_id = c.id)
  Buffers: shared hit=4210 read=98240
  ->  Seq Scan on orders o  (cost=0.00..154200.00 rows=25000 width=36) (actual time=0.042..1420.120 rows=24150 loops=1)
        Filter: (status = 'PENDING' AND created_at >= '2026-08-01'::timestamptz)
        Rows Removed by Filter: 9975850
        Buffers: shared hit=1200 read=96800
  ->  Hash  (cost=21000.00..21000.00 rows=50000 width=16) (actual time=35.120..35.120 rows=50000 loops=1)
        Buckets: 65536  Batches: 1  Memory Usage: 2840kB
        Buffers: shared hit=3010 read=1440
        ->  Seq Scan on customers c  (cost=0.00..21000.00 rows=50000 width=16)
```

---

## 2. Expected Senior Candidate Analysis
1. **Identify the Bottleneck Node**:
   - `Seq Scan on orders o` took **1,420ms** out of the 1,840ms total execution time.
   - It read **96,800 8KB disk pages** (~774 MB of I/O).
   - `Rows Removed by Filter: 9975850`: It scanned nearly 10 million rows just to retain 24,150 rows ($< 0.25\%$ of the table).
2. **Determine Remediation**:
   - High selectivity filter ($0.24\%$) on `status` and `created_at`.
   - Apply the **Equality Before Range Rule**: create composite index on `(status, created_at)`.
   - Even better: since `'PENDING'` is a transient state (most orders are COMPLETED), use a **Partial Index**:
     ```sql
     CREATE INDEX CONCURRENTLY idx_orders_pending_created
     ON orders (created_at)
     WHERE status = 'PENDING';
     ```
3. **Projected Impact**:
   - Plan will shift from `Seq Scan` (96,800 page reads) to a `Bitmap Index Scan` (~150 page reads).
   - Execution time drops from **1,840ms to $< 5\text{ms}$**.
