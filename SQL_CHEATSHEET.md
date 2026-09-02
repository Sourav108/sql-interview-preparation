# Master SQL & PostgreSQL Interview Cheatsheet

A high-density quick-reference guide covering SQL syntax, engine execution rules, indexing mechanics, transaction isolation, and interview traps.

---

## ⚡ 1. Logical Query Processing Order

SQL is written declaratively, but processed in a strict logical order:

$$\begin{aligned}
\text{Step 1: } & \mathbf{FROM} \text{ \& } \mathbf{JOIN} & \implies & \text{Identify relations and apply join ON predicates} \\
\text{Step 2: } & \mathbf{WHERE} & \implies & \text{Filter individual rows before grouping} \\
\text{Step 3: } & \mathbf{GROUP\ BY} & \implies & \text{Group rows into distinct aggregate buckets} \\
\text{Step 4: } & \mathbf{HAVING} & \implies & \text{Filter aggregate buckets (post-grouping)} \\
\text{Step 5: } & \mathbf{SELECT} & \implies & \text{Evaluate expressions, aliases, and projections} \\
\text{Step 6: } & \mathbf{DISTINCT} & \implies & \text{Eliminate duplicate result rows} \\
\text{Step 7: } & \mathbf{WINDOW} & \implies & \text{Compute window function frames (OVER clause)} \\
\text{Step 8: } & \mathbf{ORDER\ BY} & \implies & \text{Sort the final projected row set} \\
\text{Step 9: } & \mathbf{LIMIT\ /\ OFFSET} & \implies & \text{Paginate and restrict row count}
\end{aligned}$$

> **Key Rule**: `WHERE` cannot reference `SELECT` aliases because `WHERE` runs before `SELECT`. `ORDER BY` *can* reference `SELECT` aliases because it runs after.

---

## ⚡ 2. Joins & Multiplicity Quick Reference

| Join Type | Returns | Unmatched Rows | Trap / Watch Out |
| :--- | :--- | :--- | :--- |
| **`INNER JOIN`** | Rows matching `ON` predicate in both tables | Dropped entirely | Drops valid parents with 0 children |
| **`LEFT JOIN`** | All left rows + matching right rows | Right columns filled with `NULL` | `WHERE right.col = 'val'` converts it to INNER JOIN! |
| **`RIGHT JOIN`** | All right rows + matching left rows | Left columns filled with `NULL` | Mirror of LEFT JOIN (prefer LEFT JOIN for readability) |
| **`FULL JOIN`** | All rows from both tables | Unmatched filled with `NULL` | Cartesian risk on unconstrained multi-table joins |
| **`CROSS JOIN`** | Cartesian product ($M \times N$ rows) | N/A | Missing join condition in `FROM a, b` defaults to this |
| **`SEMI JOIN`** | Left rows where match exists (`EXISTS`) | No duplicate row expansion | Do not use `JOIN + DISTINCT` as a substitute |
| **`ANTI JOIN`** | Left rows where no match exists (`NOT EXISTS`) | Omitted | `NOT IN` fails silently if subquery contains NULL |

---

## ⚡ 3. Window Functions & Framing

$$\text{FUNCTION}()\ \mathbf{OVER}\ (\mathbf{PARTITION\ BY}\ \text{col}_1\ \mathbf{ORDER\ BY}\ \text{col}_2\ [\mathbf{FRAME}])$$

### Ranking Functions Comparison

| Value Set | `ROW_NUMBER()` | `RANK()` | `DENSE_RANK()` |
| :--- | :---: | :---: | :---: |
| `[100, 100, 90, 80]` | `1, 2, 3, 4` | `1, 1, 3, 4` *(skips)* | `1, 1, 2, 3` *(no skip)* |

### Window Framing Modes
- `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`: Cumulative sum from partition start to current row.
- `ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING`: Centered 3-row moving calculation.
- `RANGE BETWEEN ...`: Value-based offset (aggregates ties together by default).

---

## ⚡ 4. Three-Valued Logic (Kleene Logic)

| Expression | Evaluates To | Impact in `WHERE` / `JOIN` |
| :--- | :---: | :--- |
| `5 = 5` | `TRUE` | Row passes filter |
| `5 = 10` | `FALSE` | Row excluded |
| `5 = NULL` | `UNKNOWN` | Row excluded (only `TRUE` passes `WHERE`) |
| `NULL = NULL` | `UNKNOWN` | Row excluded! Must use `col IS NULL` |
| `TRUE AND UNKNOWN` | `UNKNOWN` | Row excluded |
| `FALSE AND UNKNOWN` | `FALSE` | Row excluded |
| `TRUE OR UNKNOWN` | `TRUE` | Row passes filter |
| `NOT (UNKNOWN)` | `UNKNOWN` | Row excluded |

---

## ⚡ 5. Indexing & B-Tree Rules

1. **Leftmost Prefix Rule**: A composite index on `(A, B, C)` can serve queries on:
   - `WHERE A = 1` ✅
   - `WHERE A = 1 AND B = 2` ✅
   - `WHERE A = 1 AND B = 2 AND C = 3` ✅
   - `WHERE B = 2 AND C = 3` ❌ *(Cannot seek; requires full index scan)*
2. **Equality Before Range**: Place high-cardinality equality columns first in composite indexes, followed by range filters:
   - Query: `WHERE status = 'ACTIVE' AND created_at >= '2026-01-01'`
   - Optimal Index: `CREATE INDEX idx_status_created ON orders (status, created_at)`
3. **Covering Indexes (Index-Only Scans)**:
   - `CREATE INDEX idx_user_cover ON users (email) INCLUDE (first_name, last_name)`
   - Serves `SELECT first_name, last_name FROM users WHERE email = ?` directly from B-Tree leaf pages without touching the heap table.

---

## ⚡ 6. Transaction Isolation Levels & Phenomena

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Serialization Anomaly |
| :--- | :---: | :---: | :---: | :---: |
| **`READ UNCOMMITTED`** *(In Postgres: Acts as Read Committed)* | Allowed (Standard) | Allowed | Allowed | Allowed |
| **`READ COMMITTED`** *(Postgres Default)* | ❌ Prevented | Allowed | Allowed | Allowed |
| **`REPEATABLE READ`** | ❌ Prevented | ❌ Prevented | ❌ Prevented *(In Postgres)* | Allowed (Write Skew) |
| **`SERIALIZABLE`** | ❌ Prevented | ❌ Prevented | ❌ Prevented | ❌ Prevented |

---

## ⚡ 7. PostgreSQL Key Diagnostics & System Views

```sql
-- 1. Check currently active long-running queries
SELECT pid, now() - query_start AS duration, query, state
FROM pg_stat_activity
WHERE state != 'idle' AND (now() - query_start) > INTERVAL '5 seconds'
ORDER BY duration DESC;

-- 2. Find table and index bloat / sizes
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_indexes_size(relid)) AS index_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- 3. Kill a blocking query PID safely
SELECT pg_cancel_backend(pid);      -- Graceful interrupt
SELECT pg_terminate_backend(pid);   -- Hard kill
```
