# Version Specification & Tooling Baseline

This repository establishes a strict, reproducible version baseline for all SQL syntax, execution plans, cost models, performance labs, and database design benchmarks.

---

## 1. Primary Database Engine

| Component | Target Version | Release Status | Notes |
| :--- | :--- | :--- | :--- |
| **PostgreSQL** | **18.6** (GA) | Stable Production GA | Primary reference database. Backwards-compatible demonstrations verified on PostgreSQL 16.x and 17.x. |
| **SQL Standard** | **ISO/IEC 9075:2023 (SQL:2023)** | Standard Baseline | Core SQL syntax conforms to SQL:2023 foundation standard; PostgreSQL extensions are explicitly demarcated. |

---

## 2. Containerization & Infrastructure Runtime

| Tool | Version Baseline | Purpose |
| :--- | :--- | :--- |
| **Docker Engine** | `27.x` or higher | Reproducible local PostgreSQL instances and multi-container replication labs. |
| **Docker Compose** | `v2.29+` (Compose Spec) | Orchestrating primary-replica setups, pgvector labs, and benchmarking containers. |
| **PostgreSQL Official Image** | `postgres:18.6-alpine` / `postgres:18.6` | Canonical Docker image used for local seed execution and labs. |

---

## 3. Integration & Testing Ecosystem

| Library / Tool | Version Baseline | Purpose |
| :--- | :--- | :--- |
| **Testcontainers (Java)** | `2.0.5` | Programmatic container lifecycle for schema migration, concurrency, and constraint tests. |
| **PostgreSQL JDBC Driver** | `42.7.13` | Type-safe connection pooling and binary protocol communication benchmark baseline. |
| **Flyway Core** | `10.x+` | DDL versioning and migration testing validation. |

---

## 4. SQL Client & Diagnostics Tooling

| Client / Utility | Recommended Tooling | Capabilities Utilized |
| :--- | :--- | :--- |
| **psql CLI** | PostgreSQL 18.6 interactive terminal | `\timing`, `\d+`, `\x`, `\ef`, `\copy`, query execution benchmarking. |
| **pg_stat_statements** | PostgreSQL Contrib Module | Real-time query execution metrics, mean time, calls, and buffer hits. |
| **pgcli** | Auto-completion & syntax highlighting CLI | Interactive query building and sandbox experimentation. |
| **DBeaver / DataGrip** | Modern Database IDEs | Visual execution plan inspections, ER diagrams, and transaction debugging. |

---

## 5. Dialect & Cross-Engine Portability Policy

1. **PostgreSQL as Source of Truth**: All physical query execution plans (`EXPLAIN ANALYZE`), locking mechanisms, MVCC tuple lifecycles, and indexing internals are validated directly against PostgreSQL 18.6.
2. **Explicit Labeling of Extensions**:
   - `[Standard SQL]`: Portable across PostgreSQL, MySQL 8+, Oracle, and SQL Server (e.g., standard window functions, ANSI JOIN syntax, CTEs).
   - `[PostgreSQL Specific]`: Constructs unique to Postgres (e.g., `DISTINCT ON`, `JSONB` operators, `CREATE INDEX CONCURRENTLY`, `FILTER (WHERE ...)`, `RETURNING`, `EXCLUDE USING gist`).
3. **Dialect Comparison Notes**: When comparative behaviors differ meaningfully (e.g., `LIMIT` vs `FETCH FIRST`, string concatenation `||` vs `CONCAT()`, `NULLS FIRST/LAST`), side-by-side behavioral notes are provided for MySQL 8+, Oracle, and SQL Server without diluting the core curriculum.
