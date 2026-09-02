# 02. The Schema Hierarchy

## 1. Problem

As a database system scales, raw tables need organization. Multiple applications may share a PostgreSQL cluster. Schema namespacing prevents naming collisions and enables access-control boundaries.

---

## 2. Concept: The Four-Level Hierarchy

```
PostgreSQL Cluster (Server Instance)
├── Database: "ecommerce_db"
│   ├── Schema: "public"
│   │   ├── Table: "users"
│   │   │   ├── Column: id BIGINT PRIMARY KEY
│   │   │   ├── Column: email VARCHAR(255) NOT NULL UNIQUE
│   │   │   └── Column: created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
│   │   └── Table: "orders"
│   ├── Schema: "analytics"
│   │   └── Table: "daily_revenue_summary"
│   └── Schema: "audit"
│       └── Table: "audit_log"
└── Database: "warehouse_db"
    └── Schema: "public"
        └── Table: "products"
```

| Level | Concept | PostgreSQL Object | Purpose |
| :--- | :--- | :--- | :--- |
| **1** | Instance | PostgreSQL Server / Cluster | One running PostgreSQL process |
| **2** | Database | `CREATE DATABASE` | Isolated data container; cross-database queries require `dblink` or FDW |
| **3** | Schema | `CREATE SCHEMA` | Namespace within a database; `public` is the default |
| **4** | Table | `CREATE TABLE` | The core relation storing rows |
| **4** | View | `CREATE VIEW` | Virtual table over a query |
| **4** | Index | `CREATE INDEX` | Storage structure accelerating lookups |
| **4** | Sequence | `CREATE SEQUENCE` | Auto-incrementing integer generator |
| **4** | Function | `CREATE FUNCTION` | Callable PL/pgSQL or SQL procedure |

---

## 3. Key DDL Operations

```sql
-- Create a schema namespace
CREATE SCHEMA IF NOT EXISTS analytics;

-- Create a table in a specific schema
CREATE TABLE analytics.daily_revenue_summary (
    summary_date   DATE           NOT NULL,
    total_revenue  NUMERIC(14, 2) NOT NULL DEFAULT 0,
    order_count    INTEGER        NOT NULL DEFAULT 0,
    PRIMARY KEY (summary_date)
);

-- The default search path resolves "public" schema first
-- Fully qualified name avoids ambiguity:
SELECT * FROM analytics.daily_revenue_summary;
```

> **[PostgreSQL Specific]**: The `search_path` variable determines which schemas PostgreSQL checks when a table is referenced without a schema prefix:
> ```sql
> SHOW search_path;               -- typically: "$user", public
> SET search_path TO myapp, public;
> ```

---

## 4. Columns and Data Types

Every column has:
1. A **name** (identifier).
2. A **data type** (domain of values).
3. Zero or more **constraints** (`NOT NULL`, `UNIQUE`, `DEFAULT`, `CHECK`).

### Common PostgreSQL Data Types

| Category | Types | Notes |
| :--- | :--- | :--- |
| **Integer** | `SMALLINT`, `INTEGER`, `BIGINT` | 2, 4, 8 bytes |
| **Auto-Increment** | `BIGSERIAL`, `GENERATED ALWAYS AS IDENTITY` | `IDENTITY` is SQL Standard, preferred over `SERIAL` |
| **Decimal** | `NUMERIC(precision, scale)`, `DECIMAL` | Exact; use for money |
| **Floating Point** | `REAL`, `DOUBLE PRECISION` | Inexact; avoid for financial calculations |
| **Text** | `TEXT`, `VARCHAR(n)`, `CHAR(n)` | `TEXT` has no practical size limit in PostgreSQL |
| **Boolean** | `BOOLEAN` | `TRUE` / `FALSE` / `NULL` |
| **Temporal** | `DATE`, `TIME`, `TIMESTAMP`, `TIMESTAMPTZ`, `INTERVAL` | Always use `TIMESTAMPTZ` for event timestamps |
| **UUID** | `UUID` | 128-bit; good for distributed surrogate keys |
| **JSON** | `JSON`, `JSONB` | `JSONB` is binary-indexed, usually preferred |
| **Array** | `INTEGER[]`, `TEXT[]` | PostgreSQL extension |
| **Enumerated** | `CREATE TYPE status_enum AS ENUM (...)` | Type-safe status values |

> **[PostgreSQL Specific]**: Prefer `TIMESTAMPTZ` (timestamp with time zone) over `TIMESTAMP` for storing event times. PostgreSQL stores `TIMESTAMPTZ` as UTC internally and converts on read using the session time zone.

---

## 5. Interview Questions

**Q1: What is a schema in PostgreSQL and how does it differ from a database?**
A schema is a namespace within a database. Multiple schemas can exist inside a single database, sharing the same connection, transaction, and memory. Databases are fully isolated — cross-database queries require foreign data wrappers or dblink. Schemas are useful for organizing tables by functional area (e.g., `analytics`, `audit`, `public`) or for multi-tenant isolation.

**Q2: Why use `TIMESTAMPTZ` instead of `TIMESTAMP`?**
`TIMESTAMP` stores a local datetime with no time zone context. If your application or database server changes time zones (DST transitions, server migrations), historical timestamps become ambiguous. `TIMESTAMPTZ` stores UTC internally and converts to the session's configured time zone on retrieval, ensuring unambiguous temporal semantics.

**Q3: Should you use `TEXT` or `VARCHAR(255)` in PostgreSQL?**
In PostgreSQL, `TEXT` and `VARCHAR` have identical storage and performance characteristics (both store variable-length strings on the heap). `VARCHAR(n)` adds a length check constraint. Use `VARCHAR(n)` when the length limit is a meaningful business constraint (e.g., an ISO country code must be 2 characters). Otherwise, `TEXT` avoids artificial truncation.

---

## 6. Further Reading
- [PostgreSQL 18 Documentation: Schema](https://www.postgresql.org/docs/18/ddl-schemas.html)
- [PostgreSQL 18 Documentation: Data Types](https://www.postgresql.org/docs/18/datatype.html)
