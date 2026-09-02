# Cheatsheet 02: Joins & Aggregations Quick Reference

## ⚡ 1. Join Types & Semantics

| Join Type | Returns | Unmatched Handling | Common Pitfall |
| :--- | :--- | :--- | :--- |
| **`INNER JOIN`** | Rows matching in both tables | Dropped entirely | Drops valid parents with 0 children |
| **`LEFT JOIN`** | All left rows + matching right rows | Unmatched right $\to$ `NULL` | Filter in `WHERE` converts to INNER JOIN |
| **`CROSS JOIN`** | Cartesian product ($M \times N$ rows) | All combinations | Accidental omission of join predicate |
| **`SEMI JOIN`** | Left rows with at least 1 match | No row expansion | Do NOT use `INNER JOIN + DISTINCT` |
| **`ANTI JOIN`** | Left rows with zero matches | No row expansion | `NOT IN` fails silently if subquery has NULL |

---

## ⚡ 2. COUNT & Aggregation Rules

- **`COUNT(*)`**: Counts all rows in group (including NULLs).
- **`COUNT(column)`**: Counts only rows where `column IS NOT NULL`.
- **`COUNT(DISTINCT column)`**: Counts unique non-null values.
- **`SUM(column)` on empty set / all NULLs**: Returns **`NULL`**, not 0! (Wrap with `COALESCE(SUM(col), 0)`).
- **`AVG(column)`**: Divides by non-null row count only.
