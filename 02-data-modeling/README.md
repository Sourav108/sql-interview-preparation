# Module 02: Data Modeling

## Learning Objectives

By the end of this module, you will be able to:
- Extract entities and relationships from a business requirement document.
- Model cardinality: 1:1, 1:N, and M:N relationships correctly.
- Build junction tables for many-to-many relationships.
- Design a normalized e-commerce schema from scratch.
- Identify identifying vs. non-identifying relationships.
- Recognize when to use composite PKs vs. surrogate PKs.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-entities-and-attributes.md](01-entities-and-attributes.md) | From business language to entities and attributes |
| [02-relationships-and-cardinality.md](02-relationships-and-cardinality.md) | 1:1, 1:N, M:N with ERD notation |
| [03-ecommerce-schema.md](03-ecommerce-schema.md) | Full e-commerce domain modeling walkthrough |
| [04-modeling-exercises.md](04-modeling-exercises.md) | Practice: banking, social network, subscriptions |

---

## Core Modeling Workflow

```
Business Requirement (English)
          │
          ▼
  Identify Nouns → Entities (Tables)
  Identify Verbs  → Relationships (FK / Junction)
  Identify Adjectives → Attributes (Columns)
          │
          ▼
  Draw ERD (Crow's Foot or UML)
          │
          ▼
  Define Keys + Constraints
          │
          ▼
  Write DDL → Validate with sample queries
```
