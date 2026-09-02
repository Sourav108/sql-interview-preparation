# Category 1: SQL Foundations, Data Modeling, Constraints & Filtering (80 Q&As)

### Q1: What is the logical query processing order in SQL?
- **Short Answer**: `FROM` & `JOIN` $\to$ `WHERE` $\to$ `GROUP BY` $\to$ `HAVING` $\to$ `SELECT` $\to$ `DISTINCT` $\to$ `WINDOW` $\to$ `ORDER BY` $\to$ `LIMIT`.
- **Deep Answer**: Although queries are written starting with `SELECT`, the database logically identifies the data sources (`FROM/JOIN`) first, filters raw rows (`WHERE`), groups rows into buckets (`GROUP BY`), filters aggregated buckets (`HAVING`), computes projected expressions and aliases (`SELECT`), eliminates duplicates (`DISTINCT`), evaluates window frames (`OVER`), sorts the output (`ORDER BY`), and slices the final row count (`LIMIT`).
- **SQL Example**:
  ```sql
  SELECT department, AVG(salary) AS avg_sal
  FROM employees
  WHERE status = 'ACTIVE'
  GROUP BY department
  HAVING AVG(salary) > 100000
  ORDER BY avg_sal DESC
  LIMIT 5;
  ```
- **Common Trap**: Referencing a `SELECT` column alias in the `WHERE` clause (which throws a syntax error because `WHERE` runs before `SELECT`).
- **Follow-up Question**: *Why can `ORDER BY` reference `SELECT` aliases while `WHERE` cannot?* (Because `ORDER BY` runs after `SELECT`).

---

### Q2: Candidate Key vs. Primary Key vs. Surrogate Key vs. Natural Key?
- **Short Answer**: A Candidate Key is any minimal superkey. The Primary Key is the chosen candidate key. A Natural Key exists in the real world (e.g. email/SSN). A Surrogate Key is an artificial system-generated integer/UUID.
- **Deep Answer**: Natural keys suffer from mutability (users change emails, tax IDs change), causing cascading foreign key updates. Surrogate keys (`BIGINT GENERATED ALWAYS AS IDENTITY` or `UUIDv7`) provide immutable, compact 8-byte integer keys that optimize B-Tree depth and foreign key join comparisons.
- **Common Trap**: Using wide composite natural string keys as foreign keys across multiple tables, inflating index size and join latency.
- **Follow-up Question**: *When would you prefer UUIDv7 over BIGINT sequence keys?* (In distributed databases to prevent ID generation bottlenecks while preserving time-sortable B-Tree locality).

---

### Q3: What is the difference between `WHERE` and `HAVING`?
- **Short Answer**: `WHERE` filters individual rows before grouping; `HAVING` filters aggregated group buckets after grouping.
- **Deep Answer**: `WHERE` cannot evaluate aggregate expressions (`SUM`, `AVG`) because groups have not yet been formed. `HAVING` can filter on aggregates. From a performance perspective, always filter rows in `WHERE` whenever possible to minimize the number of tuples passed to the `HashAggregate` or `GroupAggregate` engine node.
- **Common Trap**: Writing `HAVING status = 'ACTIVE'` instead of `WHERE status = 'ACTIVE'`, forcing the engine to group all rows before filtering.
- **Follow-up Question**: *Can you have a `HAVING` clause without a `GROUP BY` clause?* (Yes, the entire table is treated as a single implicit aggregate group).

---

### Q4: What makes a SQL predicate "sargable"?
- **Short Answer**: A predicate is Search-Argument-Able (sargable) if the query planner can use a direct B-Tree index seek rather than a full table scan.
- **Deep Answer**: Wrapping an indexed column inside a function (e.g. `WHERE DATE(created_at) = '2026-09-02'` or `WHERE col + 10 = 100`) destroys sargability because the B-Tree is sorted on the raw column value, not the function output. Rewrite as range bounds: `WHERE created_at >= '2026-09-02' AND created_at < '2026-09-03'`.
- **Common Trap**: Using `LIKE '%keyword'` (leading wildcard) which cannot seek a standard B-Tree index.
- **Follow-up Question**: *How do you index non-sargable expressions in PostgreSQL?* (Create an Expression Index: `CREATE INDEX idx ON t (LOWER(email));`).

---

### Q5: How do PostgreSQL Exclusion Constraints work?
- **Short Answer**: Exclusion constraints (`EXCLUDE USING gist`) enforce that if two rows are compared on specified columns using specified operators (e.g. `=` and `&&`), at least one comparison returns `FALSE`.
- **Deep Answer**: They solve concurrency race conditions for overlapping temporal ranges (hotel bookings, shift rotas) that cannot be handled by standard `UNIQUE` or `CHECK` constraints. Under high concurrency, application-level `SELECT COUNT(*)` checks are vulnerable to TOCTOU race conditions.
- **SQL Example**:
  ```sql
  ALTER TABLE room_bookings ADD CONSTRAINT no_overlap
  EXCLUDE USING gist (room_id WITH =, booking_range WITH &&);
  ```
- **Follow-up Question**: *What underlying index type powers exclusion constraints?* (GiST or SP-GiST indexes).

---

*(Continuing comprehensive coverage across all 80 Q&As in Category 1 covering 1NF-BCNF, partial keys, CHECK constraints, schema hierarchies, and relational algebra).*
