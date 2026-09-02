# Module 01: SQL Foundations

## Learning Objectives

By the end of this module, you will be able to:
- Explain the relational model and why it dominates enterprise data storage.
- Navigate the schema hierarchy from Database down to Column.
- Distinguish primary, candidate, natural, and surrogate keys.
- Define referential integrity and its role in data consistency.
- Classify every SQL statement into DDL, DML, DQL, DCL, or TCL.
- Build relational algebra intuition for `SELECT`, `JOIN`, and set operations.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-relational-model.md](01-relational-model.md) | Relational theory, tuples, relations, and the Codd model |
| [02-schema-hierarchy.md](02-schema-hierarchy.md) | Database → Schema → Table → Row → Column |
| [03-primary-and-foreign-keys.md](03-primary-and-foreign-keys.md) | Keys, referential integrity, and constraints |
| [04-sql-categories.md](04-sql-categories.md) | DDL, DML, DQL, DCL, TCL classification |
| [05-relational-algebra.md](05-relational-algebra.md) | Σ, π, ⨝, and set operation intuition |

---

## Key Concepts

```
Relational Database
        │
        ▼
    Schema (Namespace)
        │
        ▼
    Table (Relation)
        │
        ▼
    Row (Tuple)  ←──────→  Primary Key (unique identifier)
        │
        ▼
    Column (Attribute)  ←──────→  Data Type + Constraint
```
