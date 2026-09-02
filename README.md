# SQL Interview Preparation

> **A deep, implementation-first SQL interview preparation curriculum and database engineering guide for experienced backend engineers targeting SDE2, Senior, Staff, and Database-heavy engineering roles.**

---

## 🎯 Target Audience & Goals

This repository is designed for experienced backend software engineers, data engineers, and technical leaders preparing for rigorous SQL and database architecture interviews at top tech companies.

It bridges the gap between writing simple queries and truly understanding **relational modeling**, **execution engine mechanics**, **query plan cost models**, **MVCC concurrency**, **transaction isolation**, and **production database performance debugging**.

```
Business Requirement
        ↓
 Understand Data
        ↓
   Model Tables
        ↓
    Write SQL
        ↓
Validate Correctness
        ↓
Understand Execution
        ↓
     Optimize
        ↓
 Handle Edge Cases
        ↓
 Explain Trade-offs
        ↓
Solve Interview Problem
```

### The Core Methodology: `READ → MODEL → QUERY → VERIFY → OPTIMIZE → EXPLAIN`
This repository trains you to answer the 8 critical engineering dimensions of any SQL interview problem:
1. **What problem does this solve?**
2. **How does SQL express the business requirement declaratively?**
3. **What happens with `NULL`s, empty sets, and duplicates?**
4. **What happens when data volume grows from $10^3$ to $10^8$ rows?**
5. **How does the database planner and executor physically execute it?**
6. **What are the common anti-patterns and performance traps?**
7. **How would an interviewer probe deeper with follow-up constraints?**
8. **How would a senior engineer defend the architectural trade-offs?**

---

## 🏗️ Repository Architecture & Curriculum Overview

The curriculum is strictly partitioned into **30 numbered modules** across 10 progressive phases:

```
sql-interview-preparation/
├── 01-sql-foundations/              # Relational model, DDL/DML/DQL/TCL, keys, schemas
├── 02-data-modeling/                # Entities, relationships, cardinality, normalization
├── 03-select-filter-sort/           # Logical query order, predicates, three-valued logic
├── 04-joins/                        # Nested loop, hash, merge joins, join multiplication
├── 05-aggregation/                  # GROUP BY, HAVING, COUNT(*)/COUNT(col), conditional agg
├── 06-subqueries-and-cte/           # Correlated subqueries, EXISTS vs IN, recursive CTEs
├── 07-window-functions/             # Framing, ranking, navigation, running aggregates
├── 08-set-operations/               # UNION ALL, INTERSECT, EXCEPT, duplicate semantics
├── 09-null-and-three-valued-logic/  # Three-valued logic, NOT IN + NULL trap, COALESCE
├── 10-date-time-and-string/         # TIMESTAMPTZ, date truncation, intervals, string ops
├── 11-case-and-conditional-sql/     # CASE expressions, FILTER clause, type casting
├── 12-constraints/                  # Primary/foreign keys, CHECK, EXCLUSION constraints
├── 13-normalization/                # 1NF to BCNF, anomalies vs pragmatic denormalization
├── 14-indexing/                     # B-trees, composite index ordering, partial/covering
├── 15-query-execution/              # Parser, planner, optimizer, executor node anatomy
├── 16-explain-and-explain-analyze/  # Reading buffers, actual vs estimated rows, costs
├── 17-query-optimization/           # Evidence-driven query rewriting, pagination, batching
├── 18-transactions-and-concurrency/ # ACID semantics, WAL, transaction lifecycles
├── 19-isolation-and-locking/        # MVCC, row/table locks, deadlocks, lost updates
├── 20-postgresql-sql/               # JSONB, arrays, partitioned tables, generated columns
├── 21-schema-migrations/            # Safe zero-downtime DDL, expand/contract pattern
├── 22-sql-security/                 # Role-based access, least privilege, SQL injection prevention
├── 23-sql-testing/                  # Integration testing, Testcontainers, constraint validation
├── 24-performance-debugging/        # 40+ production debugging scenarios, bloat, locks
├── 25-sql-interview-questions/      # 400+ deep conceptual interview Q&As with follow-ups
├── 26-sql-coding-problems/          # 300+ LeetCode/HackerRank/Production SQL problems
├── 27-advanced-sql-patterns/        # Gaps & islands, sessionization, funnels, cohorts
├── 28-database-design-interviews/   # E-commerce, banking ledger, booking, social feeds
├── 29-mock-interviews/              # 6 complete multi-round interview transcripts
└── 30-cheatsheets-and-revision/     # High-density revision sheets and mental models

Supporting Directories:
├── datasets/                        # Reusable relational schemas and deterministic seed data
├── projects/                        # 8 comprehensive real-world database implementations
└── templates/                       # Standard lesson and lab Markdown templates
```

---

## 📋 Navigation & Reference Guide

| Document | Description |
| :--- | :--- |
| [CURRICULUM.md](CURRICULUM.md) | Full 30-module syllabus, breakdown, and phase roadmap |
| [ROADMAP.md](ROADMAP.md) | Structured 6-Week preparation guide for senior backend interviews |
| [SQL_INTERVIEW_FRAMEWORK.md](SQL_INTERVIEW_FRAMEWORK.md) | The 7-step `R-E-Q-U-I-R-E` framework for solving SQL interview problems |
| [SQL_PATTERNS.md](SQL_PATTERNS.md) | Master index of 22 essential SQL query patterns with mental models |
| [SQL_ANTI_PATTERNS.md](SQL_ANTI_PATTERNS.md) | Comprehensive breakdown of dangerous SQL anti-patterns and remedies |
| [SQL_CHEATSHEET.md](SQL_CHEATSHEET.md) | Rapid-fire syntax, logical ordering, and execution cheatsheet |
| [LABS.md](LABS.md) | Directory of hands-on query plan, deadlock, and performance labs |
| [PRODUCTION_SQL_CHECKLIST.md](PRODUCTION_SQL_CHECKLIST.md) | Pre-flight and post-deployment checklist for production SQL & DDL |
| [COVERAGE_MATRIX.md](COVERAGE_MATRIX.md) | Topic-by-topic artifact tracking across theory, labs, and problems |
| [DEPENDENCY_GRAPH.md](DEPENDENCY_GRAPH.md) | Module progression graph and parallel learning tracks |
| [VERSION.md](VERSION.md) | Baseline versions for PostgreSQL 18.6, Docker, and Testcontainers |

---

## ⚡ Quickstart: Local PostgreSQL Environment

To run the schemas, seed datasets, and performance labs locally using Docker:

### 1. Start PostgreSQL 18 Container
```bash
docker run --name postgres-sql-interview \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=sql_interview_db \
  -p 5432:5432 \
  -d postgres:18.6-alpine
```

### 2. Connect via `psql`
```bash
docker exec -it postgres-sql-interview psql -U postgres -d sql_interview_db
```

### 3. Load Sample Dataset
```bash
# Example: Loading e-commerce dataset
docker exec -i postgres-sql-interview psql -U postgres -d sql_interview_db < datasets/ecommerce/schema.sql
docker exec -i postgres-sql-interview psql -U postgres -d sql_interview_db < datasets/ecommerce/seed.sql
```

---

## 🔬 Query Validation & Performance Standards

1. **No Untested SQL**: Every query, index, and constraint is validated against PostgreSQL 18.6.
2. **Evidence-Driven Performance**: We never make unsubstantiated claims like *"EXISTS is always faster than JOIN"* or *"Index scans are always better than sequential scans"*. We formulate hypotheses, inspect `EXPLAIN (ANALYZE, BUFFERS)`, measure cache hits and buffer reads, and evaluate cardinality trade-offs.
3. **Realistic Data Distributions**: Datasets model real-world skews, NULL distributions, and relational cardinality variations.

---

## 📜 Repository Boundaries

- **Database-Side Focus**: This repository owns relational schemas, SQL semantics, indexing internals, query optimization, MVCC, locking, transactions, and security.
- **Application Integration**: Application-tier framework concerns (e.g., Spring Boot `@Transactional`, JPA Hibernate caching, Java Virtual Threads) are housed in companion repositories (`spring-boot-interview-preparation`, `java-interview-preparation`), while their underlying database mechanics and isolation semantics are mastered here.

---

## 🤝 Contributing & License

Contributions following the standard lesson template and verification standards are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md).

Licensed under the [MIT License](LICENSE).
