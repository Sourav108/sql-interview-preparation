# Cheatsheet 01: SQL Syntax & Logical Execution Order

## ⚡ 1. Logical Query Processing Order

$$\begin{aligned}
\text{Step 1: } & \mathbf{FROM} \text{ \& } \mathbf{JOIN} & \implies & \text{Assemble relations and evaluate ON predicates} \\
\text{Step 2: } & \mathbf{WHERE} & \implies & \text{Filter individual rows before grouping (no aggregates allowed)} \\
\text{Step 3: } & \mathbf{GROUP\ BY} & \implies & \text{Collapse rows into aggregate group buckets} \\
\text{Step 4: } & \mathbf{HAVING} & \implies & \text{Filter aggregate group buckets} \\
\text{Step 5: } & \mathbf{SELECT} & \implies & \text{Evaluate projected expressions and aliases} \\
\text{Step 6: } & \mathbf{DISTINCT} & \implies & \text{Eliminate duplicate projected rows} \\
\text{Step 7: } & \mathbf{WINDOW} & \implies & \text{Compute window function frames (OVER clause)} \\
\text{Step 8: } & \mathbf{ORDER\ BY} & \implies & \text{Sort the final projected row set} \\
\text{Step 9: } & \mathbf{LIMIT\ /\ OFFSET} & \implies & \text{Restrict output row count and paginate}
\end{aligned}$$

---

## ⚡ 2. Sargability Cheatsheet

| Non-Sargable (Table Scan) ❌ | Sargable Rewrite (Index Seek) ✅ |
| :--- | :--- |
| `WHERE DATE(created_at) = '2026-09-02'` | `WHERE created_at >= '2026-09-02' AND created_at < '2026-09-03'` |
| `WHERE LOWER(email) = 'test@example.com'` | `WHERE email = 'test@example.com'` (or Expression Index) |
| `WHERE amount + 10 > 100` | `WHERE amount > 90` |
| `WHERE name LIKE '%keyword'` | Use `pg_trgm` GIN index or full-text search |
| `WHERE EXTRACT(YEAR FROM date_col) = 2026` | `WHERE date_col >= '2026-01-01' AND date_col < '2027-01-01'` |
