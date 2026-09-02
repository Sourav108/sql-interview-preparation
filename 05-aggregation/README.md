# Module 05: Aggregation

## Learning Objectives

By the end of this module, you will be able to:
- Explain the full aggregation pipeline: Rows → Groups → Aggregates → Filtered Groups → Result.
- Differentiate `COUNT(*)`, `COUNT(col)`, and `COUNT(DISTINCT col)` semantics.
- Apply `GROUP BY` on multiple columns and composite dimensions.
- Use `HAVING` correctly for post-aggregation filters.
- Write conditional aggregation using `CASE` and `FILTER (WHERE ...)`.
- Solve business reporting problems: revenue by period, DAU, churn rates.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-aggregation-pipeline.md](01-aggregation-pipeline.md) | Rows → Groups → Aggregates; COUNT, SUM, AVG, MIN, MAX |
| [02-group-by-and-having.md](02-group-by-and-having.md) | GROUP BY semantics, HAVING vs WHERE, composite grouping |
| [03-conditional-aggregation.md](03-conditional-aggregation.md) | CASE in aggregates, FILTER clause, pivot-style queries |
| [04-aggregation-exercises.md](04-aggregation-exercises.md) | Business reporting problems with full solutions |

---

## The Aggregation Mental Model

```
TABLE ROWS (individual records)
      │
      │  GROUP BY (collapse by dimension)
      ▼
┌─────────────────────────┐
│ Group: Engineering dept │ → COUNT=3, AVG_SALARY=115000, MAX=150000
├─────────────────────────┤
│ Group: Marketing dept   │ → COUNT=2, AVG_SALARY=100000, MAX=105000
└─────────────────────────┘
      │
      │  HAVING (filter groups, not rows)
      ▼
GROUPS WHERE AVG_SALARY > 105000 → [Engineering]
      │
      │  SELECT (project aggregate results)
      ▼
RESULT SET
```
