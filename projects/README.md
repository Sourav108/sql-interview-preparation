# Database Engineering Projects Catalog

This directory contains 8 production-grade, database-focused implementations with complete schemas, deterministic seed data, optimization indexes, and analytical validation queries.

---

## 🚀 Projects Directory

| # | Project Name | Directory | Domain & Core Architectural Focus |
| :-: | :--- | :--- | :--- |
| **01** | **E-Commerce Order & Inventory Engine** | [01-ecommerce-database/](01-ecommerce-database/) | Flash sale inventory deduction, zero overselling, order lifecycle |
| **02** | **Double-Entry Financial Banking Ledger** | [02-banking-ledger/](02-banking-ledger/) | Balance consistency invariant, atomic transfers, auditability |
| **03** | **Product Analytics & Telemetry Engine** | [03-analytics-database/](03-analytics-database/) | Sessionization, funnel drop-off, cohort retention matrices |
| **04** | **Hotel & Resource Reservation System** | [04-booking-database/](04-booking-database/) | PostgreSQL exclusion constraints (`GiST`), non-overlapping dates |
| **05** | **Multi-Tenant SaaS Subscription Platform** | [05-subscription-database/](05-subscription-database/) | Row-Level Security (RLS), prorated billing, automated invoicing |
| **06** | **High-Throughput Time-Series Event Store**| [06-high-volume-event-store/](06-high-volume-event-store/) | Declarative range partitioning, BRIN indexes, partition pruning |
| **07** | **PostgreSQL Performance & Tuning Lab** | [07-postgresql-performance-lab/](07-postgresql-performance-lab/) | EXPLAIN ANALYZE benchmarks, bloat recovery, Keyset pagination |
| **08** | **Comprehensive SQL Interview Master DB** | [08-interview-master-database/](08-interview-master-database/) | Master relational schema for practicing all 300+ interview problems |

---

## 🧪 Local Execution Quickstart
Every project contains standalone executable SQL scripts:
```bash
docker exec -i postgres-sql-interview psql -U postgres -d sql_interview_db < projects/01-ecommerce-database/schema.sql
docker exec -i postgres-sql-interview psql -U postgres -d sql_interview_db < projects/01-ecommerce-database/seed.sql
docker exec -i postgres-sql-interview psql -U postgres -d sql_interview_db < projects/01-ecommerce-database/queries.sql
```
