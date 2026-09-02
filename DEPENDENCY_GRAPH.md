# Curriculum Dependency Graph & Learning Tracks

This document maps the architectural prerequisites, conceptual flow, and parallel learning tracks across the **30 curriculum modules**.

---

## 🗺️ Visual Progression Diagram

```mermaid
graph TD
    M01["01: SQL Foundations"] --> M02["02: Data Modeling"]
    M02 --> M03["03: SELECT, Filter, Sort"]
    M03 --> M04["04: Joins"]
    M04 --> M05["05: Aggregation"]
    M05 --> M06["06: Subqueries & CTEs"]
    M06 --> M07["07: Window Functions"]
    M07 --> M08["08: Set Operations"]
    M07 --> M09["09: NULL & 3-Valued Logic"]
    M07 --> M10["10: Date, Time & Strings"]
    M07 --> M11["11: CASE & Conditionals"]
    
    M02 --> M12["12: Constraints"]
    M12 --> M13["13: Normalization"]
    M13 --> M14["14: Indexing Internals"]
    
    M04 & M05 & M14 --> M15["15: Query Execution Engine"]
    M15 --> M16["16: EXPLAIN & ANALYZE"]
    M16 --> M17["17: Query Optimization"]
    
    M01 & M12 --> M18["18: Transactions & Concurrency"]
    M18 --> M19["19: Isolation & Locking"]
    
    M14 & M17 & M19 --> M20["20: PostgreSQL Advanced SQL"]
    M20 --> M21["21: Schema Migrations"]
    M20 --> M22["22: SQL Security"]
    M20 --> M23["23: SQL Testing"]
    M17 & M19 & M20 --> M24["24: Performance Debugging"]
    
    subgraph ParallelTracks ["Parallel Application Tracks"]
        M07 & M11 --> T_CODING["26: SQL Coding Problems (300+)"]
        M02 & M13 & M19 & M21 --> T_DESIGN["28: Database Design Interviews"]
        M07 & M26 --> T_PATTERNS["27: Advanced SQL Patterns"]
        M24 & M28 --> T_MOCK["29: Mock Interview Panels"]
        M01 & M24 --> T_QUESTIONS["25: SQL Interview Questions (400+)"]
        M01 & M30 --> T_REVISION["30: Cheatsheets & Revision"]
    end
```

---

## 🧱 Core Learning Backbone

1. **Relational & Query Foundations**:
   - `01-sql-foundations` $\to$ `02-data-modeling` $\to$ `03-select-filter-sort`
   - Establishes the relational model, entity cardinality, and logical query evaluation.

2. **Multi-Table Semantics & Analytical Logic**:
   - `04-joins` $\to$ `05-aggregation` $\to$ `06-subqueries-and-cte` $\to$ `07-window-functions`
   - Covers join algorithms, row multiplication, grouping sets, framing, and recursive hierarchies.

3. **Storage, Constraints & Indexing Internals**:
   - `12-constraints` $\to$ `13-normalization` $\to$ `14-indexing`
   - Covers database-level integrity, B-Tree leaf layouts, composite ordering, and index-only scans.

4. **Execution, Diagnostics & Tuning**:
   - `15-query-execution` $\to$ `16-explain-and-explain-analyze` $\to$ `17-query-optimization`
   - Covers cost models, planner estimation skew, buffer analysis, and evidence-based rewriting.

5. **Transactions, MVCC & Concurrency**:
   - `18-transactions-and-concurrency` $\to$ `19-isolation-and-locking`
   - Covers ACID guarantees, WAL logs, snapshot isolation, deadlocks, and row locking.

6. **Production PostgreSQL Operations**:
   - `20-postgresql-sql` $\to$ `21-schema-migrations` $\to$ `22-sql-security` $\to$ `23-sql-testing` $\to$ `24-performance-debugging`
   - Covers JSONB/GIN, zero-downtime expand/contract DDL, RLS, and 40+ production incident triage runbooks.

---

## 🎯 Parallel Applied Tracks

| Track Name | Modules Involved | Ideal Start Point | Purpose |
| :--- | :--- | :--- | :--- |
| **SQL Problem Solving Track** | [26-sql-coding-problems](26-sql-coding-problems/), [27-advanced-sql-patterns](27-advanced-sql-patterns/) | After Module 07 | Practice 300+ LeetCode/HackerRank style and production queries (Gaps & Islands, Top-N). |
| **Database System Design Track** | [28-database-design-interviews](28-database-design-interviews/) | After Module 19 | Solve full architectural interview cases (E-Commerce, Banking, Booking, Subscriptions). |
| **Production Diagnostics Track** | [24-performance-debugging](24-performance-debugging/), [LABS.md](LABS.md) | After Module 19 | Triage connection spikes, autovacuum bloat, lock contention, and bad query plans. |
| **Mock Interview & Revision Track** | [25-sql-interview-questions](25-sql-interview-questions/), [29-mock-interviews](29-mock-interviews/), [30-cheatsheets-and-revision](30-cheatsheets-and-revision/) | After Module 24 | Polish verbal explanations, defend trade-offs, and conduct simulated mock panels. |
