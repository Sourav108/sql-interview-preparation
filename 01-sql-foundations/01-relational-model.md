# 01. The Relational Model

## 1. Problem

Modern applications store and retrieve structured data. Before relational databases, data lived in hierarchical file systems or network databases — querying them required navigating explicit pointers. Edgar F. Codd's 1970 paper *"A Relational Model of Data for Large Shared Data Banks"* revolutionized this: query *what* you want, not *how* to navigate to it.

**The question this answers**: *Why do we use tables, rows, and columns instead of anything else?*

---

## 2. Concept

A **relational database** organizes data as a collection of **relations** (tables). Each relation is:
- A named set of **tuples** (rows).
- Each tuple contains **attribute values** (columns) drawn from defined **domains** (data types).

Key mathematical properties of a relation:
1. **No duplicate tuples**: Every row is unique (enforced by a primary key).
2. **No order among tuples**: Rows have no inherent sequence. `ORDER BY` is always required for deterministic ordering.
3. **No order among attributes**: Column order in a result is only meaningful via explicit projection.
4. **All attribute values are atomic**: Each cell holds one indivisible value (First Normal Form).

---

## 3. Mental Model

```
RELATION (Table)
┌─────────────────────────────────────────────────────────────┐
│  Attribute 1    Attribute 2    Attribute 3    Attribute N   │
│  (Column)       (Column)       (Column)       (Column)      │
├─────────────────────────────────────────────────────────────┤
│  value          value          value          value         │  ← Tuple (Row)
│  value          value          value          value         │  ← Tuple (Row)
│  value          value          value          value         │  ← Tuple (Row)
└─────────────────────────────────────────────────────────────┘
         Rows have no inherent order.
         Every row must be uniquely identifiable.
```

---

## 4. SQL Categories

Every SQL statement belongs to one of five families:

| Category | Full Name | Purpose | Key Statements |
| :--- | :--- | :--- | :--- |
| **DDL** | Data Definition Language | Define and modify schema structure | `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, `RENAME` |
| **DML** | Data Manipulation Language | Read and write data rows | `INSERT`, `UPDATE`, `DELETE`, `MERGE` |
| **DQL** | Data Query Language | Retrieve data (sometimes classified under DML) | `SELECT` |
| **DCL** | Data Control Language | Manage access permissions | `GRANT`, `REVOKE` |
| **TCL** | Transaction Control Language | Manage transaction boundaries | `BEGIN`, `COMMIT`, `ROLLBACK`, `SAVEPOINT` |

> **[PostgreSQL Specific]**: In PostgreSQL, `DDL` statements (`CREATE TABLE`, `ALTER TABLE`, `DROP TABLE`) are transactional. They can be rolled back within an open transaction — unlike MySQL where DDL commits implicitly.

---

## 5. Example: A Simple Relation

```sql
-- [Standard SQL] Table definition
CREATE TABLE employees (
    employee_id  BIGINT       PRIMARY KEY,
    first_name   VARCHAR(50)  NOT NULL,
    last_name    VARCHAR(50)  NOT NULL,
    department   VARCHAR(50),
    salary       NUMERIC(10, 2)
);

INSERT INTO employees (employee_id, first_name, last_name, department, salary)
VALUES
    (1, 'Alice',   'Chen',    'Engineering',  105000.00),
    (2, 'Bob',     'Kapoor',  'Engineering',   98000.00),
    (3, 'Carol',   'Lima',    'Marketing',     82000.00),
    (4, 'David',   'Nakamura','Engineering',  112000.00),
    (5, 'Eva',     'Steele',  'Marketing',     79000.00);
```

---

## 6. Relational Algebra Intuition

SQL is a practical realization of **Relational Algebra**. Understanding the algebra makes SQL semantics intuitive:

| Algebra Operation | SQL Equivalent | Mental Model |
| :--- | :--- | :--- |
| **Selection** σ | `WHERE` clause | Filter rows by predicate |
| **Projection** π | `SELECT col1, col2` | Choose which columns to return |
| **Cartesian Product** × | `FROM A, B` (unjoined) | All combinations of rows from two relations |
| **Join** ⨝ | `JOIN ... ON` | Cartesian product filtered by join predicate |
| **Union** ∪ | `UNION` | Combine two result sets, discard duplicates |
| **Intersection** ∩ | `INTERSECT` | Rows that exist in both result sets |
| **Difference** − | `EXCEPT` | Rows in the first set but not the second |
| **Rename** ρ | `AS` alias | Rename a relation or attribute |

**Example**:
- σ (salary > 100000) on `employees` → rows where salary exceeds 100,000.
- π (first_name, salary) on the above → only those two columns.
- In SQL: `SELECT first_name, salary FROM employees WHERE salary > 100000;`

---

## 7. NULL in the Relational Model

`NULL` is not a value — it is the **absence of a value** (unknown or inapplicable). This creates **Three-Valued Logic** where predicates evaluate to `TRUE`, `FALSE`, or `UNKNOWN`. Null semantics are covered in depth in [Module 09](../09-null-and-three-valued-logic/).

---

## 8. Interview Questions

**Q1: What is a relation in the relational model?**
A relation is a named set of tuples (rows) where each tuple has the same set of typed attributes (columns). Formally, a relation has no duplicate rows, no inherent row ordering, and every attribute value is atomic.

**Q2: What does "declarative" mean in the context of SQL?**
SQL describes *what* data to retrieve — the engine determines *how* to physically retrieve it. You specify the predicate (e.g., `WHERE status = 'ACTIVE'`), and the query planner decides whether to use an index scan, sequential scan, or hash join.

**Q3: In PostgreSQL, can you roll back a DDL statement?**
Yes. PostgreSQL wraps DDL in the active transaction. `BEGIN; CREATE TABLE test (...); ROLLBACK;` leaves no trace of the table. This is unlike MySQL where `CREATE TABLE` auto-commits. This property is critical for safe migration scripts.

**Q4: Why does SQL not guarantee row ordering without `ORDER BY`?**
Because relations in the relational model are mathematical sets — unordered collections. The physical layout on disk (heap pages, index order) does not constitute a logical ordering guarantee. Without `ORDER BY`, PostgreSQL may return rows in any order depending on the execution plan.

---

## 9. Further Reading
- [PostgreSQL 18 Documentation: SQL Concepts](https://www.postgresql.org/docs/18/tutorial-concepts.html)
- Codd, E.F. (1970). *A Relational Model of Data for Large Shared Data Banks*. CACM.
- Date, C.J. *An Introduction to Database Systems* (Chapters 1–3).
