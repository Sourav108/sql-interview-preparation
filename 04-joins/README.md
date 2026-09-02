# Module 04: Joins

## Learning Objectives

By the end of this module, you will be able to:
- Explain how every join type works mechanically, not just syntactically.
- Predict the exact row count of a join before running it.
- Identify and prevent accidental Cartesian products.
- Understand row multiplication in 1:N and M:N joins and its effect on aggregation.
- Choose between `INNER JOIN`, `LEFT JOIN`, `EXISTS`, and `NOT EXISTS` deliberately.
- Solve the canonical join interview problems confidently.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-join-mechanics.md](01-join-mechanics.md) | How joins physically work; INNER, LEFT, RIGHT, FULL, CROSS, SELF |
| [02-join-predicates-and-traps.md](02-join-predicates-and-traps.md) | ON vs WHERE, row multiplication, outer-join filter conversion |
| [03-semi-and-anti-joins.md](03-semi-and-anti-joins.md) | EXISTS, NOT EXISTS, semi-join vs anti-join |
| [04-join-interview-problems.md](04-join-interview-problems.md) | 10 canonical interview problems with full solutions |

---

## The Join Mental Model

```
Table A (left)          Table B (right)
┌───────────────┐       ┌───────────────┐
│ a1  │ key=1   │       │ key=1 │ b1    │
│ a2  │ key=2   │       │ key=2 │ b2    │
│ a3  │ key=3   │       │ key=3 │ b3    │
│ a4  │ key=99  │       │ key=4 │ b4    │  ← no match in A
└───────────────┘       └───────────────┘

INNER JOIN  → rows where key matches in BOTH:  a1+b1, a2+b2, a3+b3
LEFT JOIN   → ALL left rows + right where match: a1+b1, a2+b2, a3+b3, a4+NULL
RIGHT JOIN  → ALL right rows + left where match: a1+b1, a2+b2, a3+b3, NULL+b4
FULL JOIN   → ALL rows from both:               a1+b1, a2+b2, a3+b3, a4+NULL, NULL+b4
CROSS JOIN  → every combination (4×4 = 16 rows)
```
