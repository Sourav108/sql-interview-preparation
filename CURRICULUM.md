# Complete SQL & Relational Engineering Curriculum

This curriculum is structured into **30 numbered modules** organized across **10 progressive phases**, taking an experienced engineer from SQL relational fundamentals to advanced query optimization, MVCC internals, distributed database design, and senior interview mastery.

---

## 🗺️ Curriculum Phase Overview

```
Phase 1: SQL Foundations & Modeling       (Modules 01–03)
Phase 2: Relational Queries & Aggregation (Modules 04–05)
Phase 3: Advanced SQL Expressions         (Modules 06–11)
Phase 4: Constraints, Schema & Indexing   (Modules 12–14)
Phase 5: Execution Engine & Optimization  (Modules 15–17)
Phase 6: Transactions, MVCC & Concurrency (Modules 18–19)
Phase 7: PostgreSQL Production Operations (Modules 20–24)
Phase 8: Interview Q&A & Problem Banks    (Modules 25–26)
Phase 9: Advanced Patterns & Mock Panels  (Modules 27–30)
Phase 10: Enterprise Database Projects    (projects/)
```

---

## 📚 Detailed 30-Module Syllabus

### Phase 1: Foundations & Relational Modeling (Modules 01–03)

#### [Module 01: SQL Foundations](01-sql-foundations/)
- Relational database theory & Codd's relational model
- Schema hierarchy: Database $\to$ Schema $\to$ Table $\to$ Row $\to$ Column
- Primary keys, candidate keys, natural keys, surrogate keys (UUIDs vs BIGSERIAL)
- Foreign keys & referential integrity constraints
- SQL command classification: DDL, DML, DQL, DCL, TCL
- Relational algebra intuition (Selection $\sigma$, Projection $\pi$, Join $\bowtie$, Set operations)

#### [Module 02: Data Modeling](02-data-modeling/)
- Business requirement extraction to Entity-Relationship (ER) modeling
- Cardinality & participation: 1:1, 1:N, M:N relationships
- Junction tables and associative entities with composite keys
- E-commerce domain modeling: `Customer` $\to$ `Order` $\to$ `OrderItem` $\to$ `Product`
- Identifying vs Non-identifying relationships
- Practical schema tradeoffs: Natural keys vs Synthetic identity columns

#### [Module 03: SELECT, Filter, and Sort](03-select-filter-sort/)
- Logical query processing order vs Physical execution order
- `SELECT`, `FROM`, `WHERE`, `DISTINCT`, `ORDER BY`, `LIMIT`, `OFFSET`
- Predicate evaluation: `IN`, `BETWEEN`, `LIKE`, `ILIKE`, `IS NULL`
- Boolean algebra & short-circuit evaluation semantics in SQL engines
- Column aliases visibility across query clauses (why `WHERE` cannot see `SELECT` aliases)
- Sorting nulls explicitly: `NULLS FIRST` vs `NULLS LAST`

---

### Phase 2: Relational Queries & Aggregations (Modules 04–05)

#### [Module 04: Joins](04-joins/)
- Deep join mechanics: `INNER JOIN`, `LEFT OUTER JOIN`, `RIGHT OUTER JOIN`, `FULL OUTER JOIN`
- Cartesian products: `CROSS JOIN` (accidental vs intentional matrix generation)
- `SELF JOIN` for hierarchical structures (Employee $\to$ Manager)
- Join predicates: `ON` clause vs `WHERE` clause filtering in outer joins
- The row multiplication problem in 1:N and M:N joins
- Semi-joins (`EXISTS`) and Anti-joins (`NOT EXISTS` / `LEFT JOIN ... WHERE NULL`)
- Interview problem masterclass: Customers with no orders, missing relations, duplicate edges

#### [Module 05: Aggregation](05-aggregation/)
- Aggregation mental model: Rows $\to$ Groups $\to$ Aggregates $\to$ Filtered Groups
- Aggregation functions: `COUNT(*)`, `COUNT(column)`, `COUNT(DISTINCT column)`, `SUM`, `AVG`, `MIN`, `MAX`
- `GROUP BY` semantics with multiple columns and composite dimensions
- `HAVING` vs `WHERE`: Pre-aggregation filtering vs Post-aggregation group filtering
- Conditional aggregation using `COUNT(CASE WHEN ...)` and `FILTER (WHERE ...)`
- Business reporting metrics: Monthly Recurring Revenue (MRR), Daily Active Users (DAU), churn

---

### Phase 3: Advanced SQL Expressions & Semantics (Modules 06–11)

#### [Module 06: Subqueries and Common Table Expressions (CTEs)](06-subqueries-and-cte/)
- Scalar subqueries, multi-row subqueries, and derived tables in `FROM`
- Correlated subqueries and their execution implications
- `EXISTS` vs `IN` vs `JOIN`: Semantic differences and query optimizer behavior
- Common Table Expressions (`WITH` clause) for readability and modularity
- Recursive CTEs for graph traversal, bill-of-materials, and organizational hierarchies
- PostgreSQL CTE materialization behavior (`MATERIALIZED` vs `NOT MATERIALIZED`)

#### [Module 07: Window Functions](07-window-functions/)
- Window function anatomy: `OVER (PARTITION BY ... ORDER BY ... FRAME ...)`
- Ranking functions: `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `NTILE()`
- Value navigation functions: `LAG()`, `LEAD()`, `FIRST_VALUE()`, `LAST_VALUE()`
- Window framing specifications: `ROWS BETWEEN` vs `RANGE BETWEEN`
- Aggregations over windows: Running totals, moving averages, year-to-date sums
- Core interview patterns: Top-N per group, second-highest salary, MoM delta, sessionization

#### [Module 08: Set Operations](08-set-operations/)
- Set theory in SQL: `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT` (MINUS)
- Duplicate retention semantics: `UNION` (implicit distinct sort) vs `UNION ALL` (pure append)
- Schema compatibility: Column count, positional mapping, and data type coercion rules
- Set operations vs Outer Joins / Anti-joins: Trade-offs in clarity and performance

#### [Module 09: NULL and Three-Valued Logic](09-null-and-three-valued-logic/)
- Kleene's 3-Valued Logic: `TRUE`, `FALSE`, `UNKNOWN`
- NULL semantics: NULL is an unknown state, not zero, not empty string
- Truth tables for `AND`, `OR`, `NOT` with `UNKNOWN`
- The classic `NOT IN (...) + NULL` trap causing empty result sets
- Safe null handling: `IS NULL`, `IS DISTINCT FROM`, `COALESCE()`, `NULLIF()`
- NULLs in sorting, unique constraints, and foreign keys

#### [Module 10: Date, Time, and String Processing](10-date-time-and-string/)
- Temporal data types: `DATE`, `TIME`, `TIMESTAMP`, `TIMESTAMPTZ`, `INTERVAL`
- Time zone handling and UTC storage best practices
- Date truncation (`DATE_TRUNC`), extraction (`EXTRACT`), and date arithmetic
- String manipulation: `SUBSTRING`, `TRIM`, `REPLACE`, `REGEXP_MATCHES`, string concatenation
- Time-series analytics: Gap filling, cohort windows, rolling 7-day metrics

#### [Module 11: CASE and Conditional SQL](11-case-and-conditional-sql/)
- Simple `CASE` vs Searched `CASE` expressions
- Short-circuiting behavior in conditional branches
- Matrix pivoting using conditional aggregation
- Type coercion and explicit casting with `CAST()` and `::`
- `COALESCE`, `NULLIF`, `GREATEST`, `LEAST` in business logic

---

### Phase 4: Constraints, Schema & Indexing (Modules 12–14)

#### [Module 12: Constraints](12-constraints/)
- Database-level integrity: `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `NOT NULL`, `CHECK`
- Foreign key cascade options: `ON DELETE CASCADE`, `ON DELETE SET NULL`, `ON DELETE RESTRICT`
- PostgreSQL exclusion constraints (`EXCLUDE USING gist`) for temporal non-overlapping ranges
- Architectural rule: Database constraints vs Application-level validation

#### [Module 13: Normalization & Practical Denormalization](13-normalization/)
- Functional dependencies and candidate keys
- Normal forms: 1NF (atomic values), 2NF (full dependency), 3NF (transitive dependency), BCNF
- Relational anomalies: Insert, Update, and Delete anomalies
- Pragmatic denormalization strategies for high-throughput reads and analytical reporting
- Materialized views, incremental refresh patterns, and cache invalidation strategies

#### [Module 14: Indexing Internals](14-indexing/)
- B-Tree index physical layout: Root, branch, leaf pages, and page pointers
- Hash indexes, BRIN indexes, GIN/GiST indexes (overview and use cases)
- Composite indexes: The leftmost prefix rule and column ordering strategy
- Special index types: Partial indexes (`WHERE active = true`), Expression/Functional indexes
- Covering indexes with `INCLUDE` clauses and Index-Only Scans
- Index selectivity, write amplification, maintenance overhead, and page splits

---

### Phase 5: Query Execution & Performance Optimization (Modules 15–17)

#### [Module 15: Query Execution Engine](15-query-execution/)
- The query lifecycle: Parser $\to$ Analyzer $\to$ Rewriter $\to$ Planner $\to$ Executor
- Cost model: Sequential page cost (`seq_page_cost`), random page cost (`random_page_cost`), CPU costs
- Scan methods: Sequential Scan, Index Scan, Index Only Scan, Bitmap Index Scan
- Join algorithms: Nested Loop Join, Hash Join, Merge Join (mechanics and memory limits)
- Parallel query execution: Parallel scans, parallel joins, worker thread allocation

#### [Module 16: EXPLAIN & EXPLAIN ANALYZE](16-explain-and-explain-analyze/)
- Reading query plans: `cost`, `rows`, `width`, `actual time`, `actual rows`, `loops`
- Buffer inspection: `EXPLAIN (ANALYZE, BUFFERS)` (Shared hit, read, dirtied, written)
- Diagnosing planner issues: Estimation skew, bad statistics, out-of-date `ANALYZE`
- Detecting expensive nodes: Large in-memory/disk sorts, hash spills, sequential scans on hot tables

#### [Module 17: Query Optimization](17-query-optimization/)
- Evidence-driven optimization protocol: Measurement over guesswork
- Query refactoring: Eliminating correlated subqueries, pushing down predicates
- Pagination at scale: Keyset / Cursor-based pagination vs `OFFSET / LIMIT`
- Batching updates and inserts to minimize WAL and lock contention
- Optimizer hints, work memory configuration (`work_mem`), and extended statistics

---

### Phase 6: Transactions, MVCC & Concurrency (Modules 18–19)

#### [Module 18: Transactions and Concurrency](18-transactions-and-concurrency/)
- ACID properties: Atomicity, Consistency, Isolation, Durability
- Transaction control: `BEGIN`, `COMMIT`, `ROLLBACK`, `SAVEPOINT`
- Write-Ahead Logging (WAL) and crash recovery mechanics (ARIES overview)
- Double-entry ledger modeling: Atomic balance transfers and invariant checks

#### [Module 19: Isolation Levels & Locking](19-isolation-and-locking/)
- ANSI SQL Isolation Levels: `READ UNCOMMITTED`, `READ COMMITTED`, `REPEATABLE READ`, `SERIALIZABLE`
- Concurrency phenomena: Dirty Reads, Non-Repeatable Reads, Phantom Reads, Lost Updates, Write Skew
- PostgreSQL Multi-Version Concurrency Control (MVCC): `xmin`, `xmax`, tuple visibility, HOT updates
- Locking hierarchy: Table-level locks, Row-level locks (`FOR UPDATE`, `FOR SHARE`, `SKIP LOCKED`)
- Deadlock detection, lock queues, lock timeouts, and mitigation strategies

---

### Phase 7: PostgreSQL Production Operations (Modules 20–24)

#### [Module 20: PostgreSQL Advanced SQL & Features](20-postgresql-sql/)
- Advanced data types: `JSONB` indexing and querying with `@>`, `?`, `->`, `->>`
- PostgreSQL Array types and array operations (`ANY`, `ALL`, `@>`)
- Partitioning strategies: Range, List, and Hash partitioning with partition pruning
- Generated columns and Identity columns (`GENERATED ALWAYS AS IDENTITY`)
- System catalog views: `pg_stat_activity`, `pg_stat_user_tables`, `pg_statio_user_tables`

#### [Module 21: Schema Migrations & Zero-Downtime DDL](21-schema-migrations/)
- Safe schema migrations in high-traffic 24/7 production systems
- The Expand / Contract (Parallel Run) migration pattern
- Zero-downtime column additions, renames, and type modifications
- Creating indexes safely without table locks: `CREATE INDEX CONCURRENTLY`
- Managing lock timeouts, migration rollback strategies, and idempotent DDL

#### [Module 22: SQL Security & Access Control](22-sql-security/)
- Authentication, Roles, Users, and the Principle of Least Privilege
- Object privileges: `GRANT`, `REVOKE`, default privileges on schemas
- SQL Injection prevention: Parameterized queries vs string concatenation vulnerabilities
- Row-Level Security (RLS) policies for multi-tenant data isolation
- Data encryption, column-level masking, and audit logging (`pgaudit`)

#### [Module 23: SQL Testing & Validation](23-sql-testing/)
- Integration testing relational databases with Testcontainers (PostgreSQL 18)
- Writing deterministic SQL regression test suites
- Testing database constraints, triggers, and foreign key cascades
- Concurrency and isolation tests: Simulating race conditions and deadlocks in automated test runs

#### [Module 24: Production Performance Debugging](24-performance-debugging/)
- 40+ Production debugging scenarios and triage runbooks
- Investigating connection pool exhaustion and idle-in-transaction connections
- Identifying table bloat, index bloat, and tuning `VACUUM` / `AUTOVACUUM`
- CPU saturation vs I/O bottleneck diagnostics using `pg_stat_statements`
- Diagnosing replication lag and WAL accumulation

---

### Phase 8: Interview Question Banks & Coding Problems (Modules 25–26)

#### [Module 25: 400+ SQL Interview Questions & Answers](25-sql-interview-questions/)
- 400+ Categorized technical interview questions with concise answers, deep architectural dives, SQL snippets, common traps, and interviewer follow-up questions across all 24 core topics.

#### [Module 26: 300+ SQL Coding Problems](26-sql-coding-problems/)
- 300+ Realistic coding problems spanning Easy, Medium, and Hard tiers across domains (e-commerce, fintech, subscriptions, logistics, social media, telemetry) with full schemas, test assertions, naive solutions, optimal solutions, and complexity analysis.

---

### Phase 9: Advanced Patterns, System Design & Mocks (Modules 27–30)

#### [Module 27: Advanced SQL Patterns](27-advanced-sql-patterns/)
- Navigational reference to 22 foundational and advanced patterns: Gaps and Islands, Sessionization, Funnel Conversion, Cohort Retention, Hierarchical Traversals, Keyset Pagination, and Pivoting.

#### [Module 28: Database Design Interviews](28-database-design-interviews/)
- 6 Full Database System Design interview cases: E-commerce Order Management, Double-Entry Banking Ledger, Ride-Hailing / Hotel Booking, Multi-Tenant SaaS Subscriptions, Social Media Activity Feed, and High-Volume IoT Telemetry.

#### [Module 29: Mock Interviews](29-mock-interviews/)
- 6 Complete multi-round interview transcripts covering Fundamentals, Live Coding, Query Optimization, Database Architecture, Production Incident Triage, and Concurrency & MVCC.

#### [Module 30: Cheatsheets & Rapid Revision](30-cheatsheets-and-revision/)
- High-density revision sheets, mental models, execution flowcharts, and quick-lookup cards for last-minute interview prep.

---

### Phase 10: Enterprise Database Projects (`projects/`)

8 Complete production-grade relational database project implementations with schemas, seeds, queries, and automated validation:
1. **E-Commerce Order & Inventory Platform**
2. **Double-Entry Financial Banking Ledger**
3. **Product Analytics & Telemetry Engine**
4. **Hotel & Resource Reservation System**
5. **Multi-Tenant SaaS Subscription & Invoicing Engine**
6. **High-Throughput Time-Series Event Store**
7. **PostgreSQL Performance & Query Tuning Lab**
8. **Comprehensive SQL Interview Master Database**
