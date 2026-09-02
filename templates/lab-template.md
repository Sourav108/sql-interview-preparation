# Lab Template: [Lab Title]

## 1. Initial State
<!-- Initial database configuration, table state, and parameters -->

## 2. Dataset
<!-- DDL and Seed script to generate test volume (e.g. 100k - 10M rows) -->
```sql
-- DDL
```

## 3. Problem
<!-- Description of the performance bottleneck, deadlock, or failure mode -->

## 4. Observation
<!-- Initial error, slow query latency, or unexpected output -->

## 5. EXPLAIN / Metrics Analysis
```sql
EXPLAIN (ANALYZE, BUFFERS)
-- Target query
```
<!-- Analysis of node types, actual rows vs estimated rows, buffer reads -->

## 6. Investigation & Root Cause
<!-- Detailed explanation of why the database behaves this way -->

## 7. Fix & Remediation
<!-- Index creation, query rewriting, configuration tuning, or transaction ordering -->
```sql
-- Remediation DDL or rewritten SQL
```

## 8. Before vs After Measurement
| Metric | Before Remediation | After Remediation | Delta / Improvement |
| :--- | :--- | :--- | :--- |
| **Execution Time** | `142.3 ms` | `0.41 ms` | `347x faster` |
| **Shared Buffer Hit/Read** | `read=12400 hit=150` | `hit=4 read=0` | `99.9% I/O reduction` |
| **Scan Type** | `Seq Scan` | `Index Only Scan` | `Direct B-Tree seek` |

## 9. Architectural Lessons & Rules
<!-- Core production takeaways and interview talking points -->
