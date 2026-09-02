# Contributing Guide & Authoring Standards

Thank you for contributing to the **SQL Interview Preparation** repository. To maintain senior-level rigor, technical depth, and reproducibility, all contributions must strictly adhere to our authoring and validation guidelines.

---

## 🏛️ Standard Lesson Template

All substantial technical lessons across modules 01–24 must follow this 18-part structure:

```markdown
# [Topic Title]

## 1. Problem
What real-world business or data retrieval challenge does this topic solve?

## 2. Concept
Formal theoretical definition and relational principles.

## 3. Mental Model
Visual intuition, ASCII/Mermaid flowcharts, or conceptual analogies.

## 4. Example Schema
Clean, executable DDL using standard PostgreSQL data types and constraints.

## 5. Sample Data
Deterministic `INSERT` statements modeling realistic skews, nulls, and edge cases.

## 6. SQL
Primary SQL query or solution implementing the requirement.

## 7. Expected Result
Exact tabular output of the query execution.

## 8. Edge Cases
Boundary conditions, empty sets, ties, zero division, and high-volume behavior.

## 9. NULL Behavior
How `NULL` values interact with this operation under 3-valued logic.

## 10. Duplicate Behavior
How duplicates in join keys, grouping columns, or rankings are handled.

## 11. How the Database Executes It
Internal parser, planner, and executor mechanics (scans, hash tables, sorts).

## 12. Performance
Time and space complexity, buffer I/O, cache locality, and indexing strategies.

## 13. Common Mistakes
Specific traps, anti-patterns, and junior vs senior code examples.

## 14. Interview Questions
Realistic interview questions asked by senior tech interviewers.

## 15. Interview Answer
Model answer demonstrating technical depth, trade-off articulation, and clarity.

## 16. Exercises
2–3 unsolved practice problems with varying difficulty tiers.

## 17. Solutions
Complete, verified SQL solutions for the exercises.

## 18. Further Reading
References to official PostgreSQL 18 documentation, papers, and books.
```

---

## 🔬 Query Validation & Quality Standards

1. **Mandatory Execution Verification**: Never commit SQL code without verifying it against the baseline **PostgreSQL 18.6** instance.
2. **No Fabricated Benchmarks**: Execution times, buffer hit statistics, and query plans in `EXPLAIN ANALYZE` outputs must reflect actual execution measurements.
3. **Dialect Transparency**: Explicitly tag non-standard SQL constructs with `[PostgreSQL Specific]`. Standard SQL constructs should be marked `[Standard SQL]`.
4. **Boundary Isolation**: Do not replicate application-layer Spring Boot or Java code here. Focus exclusively on database schemas, SQL semantics, query plans, and concurrency.

---

## 🛠️ Contribution Workflow

1. Fork or branch from `main`.
2. Author your lesson or problem according to the corresponding template in `templates/`.
3. Test all SQL snippets against the local PostgreSQL test container:
   ```bash
   docker exec -i postgres-sql-interview psql -U postgres -d sql_interview_db < your_test.sql
   ```
4. Verify formatting and whitespace:
   ```bash
   git diff --check
   ```
5. Submit a pull request with a descriptive commit message following Conventional Commits (e.g. `feat: add window framing deep dive`).
