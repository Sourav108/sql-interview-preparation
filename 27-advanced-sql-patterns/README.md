# Module 27: Advanced SQL Patterns Index

This module acts as the structured curriculum reference for advanced relational querying patterns. Detailed pattern templates, mental models, and performance considerations are indexed in [SQL_PATTERNS.md](../SQL_PATTERNS.md), with full worked coding implementations in [26-sql-coding-problems/](../26-sql-coding-problems/).

---

## 🧭 Core Pattern Quick Reference

| # | Pattern Name | Concept Class | Worked Problem Reference |
| :-: | :--- | :--- | :--- |
| **01** | **Anti-Join (Exclusion)** | `NOT EXISTS` / `LEFT JOIN WHERE NULL` | [Problem E01](../26-sql-coding-problems/01-easy-problems.md#problem-e01-customers-who-never-ordered) |
| **02** | **Semi-Join (Existence)** | `WHERE EXISTS` / `Hash Semi Join` | [Lab 17.1](../17-query-optimization/labs/lab-01-slow-query-rewrite.md) |
| **03** | **Top-N Per Group** | `DENSE_RANK() OVER (PARTITION BY ...)` | [Problem M01](../26-sql-coding-problems/02-medium-problems.md#problem-m01-top-3-highest-paid-employees-per-department) |
| **04** | **Running Balance / Overdraft** | `SUM() OVER (ROWS BETWEEN ...)` | [Problem M02](../26-sql-coding-problems/02-medium-problems.md#problem-m02-running-balance--account-overdraft-detection) |
| **05** | **Month-over-Month (MoM) Delta**| `LAG()`, `NULLIF` | [Problem M03](../26-sql-coding-problems/02-medium-problems.md#problem-m03-month-over-month-mom-revenue-growth-rate) |
| **06** | **Gaps and Islands** | `ROW_NUMBER()` Row-Difference Grouping | [Problem H01](../26-sql-coding-problems/03-hard-problems.md#problem-h01-gaps-and-islands--user-login-streaks) |
| **07** | **Clickstream Sessionization** | `LAG()` $\Delta t > 30\text{m}$, Cumulative Sum | [Problem H02](../26-sql-coding-problems/03-hard-problems.md#problem-h02-clickstream-sessionization-30-minute-inactivity-window) |
| **08** | **Funnel Drop-off & Conversion**| Conditional Aggregation `MAX(CASE ...)`| [Problem H03](../26-sql-coding-problems/03-hard-problems.md#problem-h03-funnel-drop-off--conversion-rate) |
| **09** | **Recursive Hierarchy / BOM** | `WITH RECURSIVE` Parent-Child Traversal | [Problem H04](../26-sql-coding-problems/03-hard-problems.md#problem-h04-recursive-bill-of-materials-assembly-tree-cost) |
| **10** | **Keyset / Cursor Pagination** | `WHERE (created_at, id) < (...)` | [Lab 17.2](../17-query-optimization/labs/lab-02-deep-offset-pagination.md) |
| **11** | **Calendar Date Gap Filling** | `generate_series()` + `LEFT JOIN` | [Module 10](../10-date-time-and-string/01-temporal-types-and-arithmetic.md#6-generate_series--gap-filling) |
| **12** | **Multi-Row Deduplication** | `ROW_NUMBER()` Tiebreaker Partitioning | [SQL_PATTERNS.md Pattern 14](../SQL_PATTERNS.md#14-deduplication-with-priority) |
