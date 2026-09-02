# E-Commerce Dataset

The canonical multi-table e-commerce dataset used across Modules 01–17. Designed to be:
- **Deterministic**: Same data every run.
- **Realistic**: Skewed distributions, NULLs, multiple status values, order history.
- **Large enough**: 10,000 customers, 100,000 orders, 500,000 order items for performance experiments.

## Files

| File | Purpose |
| :--- | :--- |
| [schema.sql](schema.sql) | Full DDL: all tables, indexes, types, constraints |
| [seed.sql](seed.sql) | Sample data for development and testing (small, deterministic) |
| [seed-large.sql](seed-large.sql) | Performance-scale data generator using `generate_series` |
| [queries.sql](queries.sql) | Reference validation queries verifying correct schema behavior |

## Quick Start

```bash
docker exec -i postgres-sql-interview psql -U postgres -d sql_interview_db < datasets/ecommerce/schema.sql
docker exec -i postgres-sql-interview psql -U postgres -d sql_interview_db < datasets/ecommerce/seed.sql
```
