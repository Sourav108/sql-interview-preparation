# Module 14: Indexing Internals & Optimization

## Learning Objectives

By the end of this module, you will be able to:
- Explain the physical B-Tree index structure (root, branch, leaf pages, TIDs).
- Design optimal composite indexes using the **Leftmost Prefix Rule** and **Equality-Before-Range** strategy.
- Eliminate heap access using **Covering Indexes** (`INCLUDE` clause) and **Index-Only Scans**.
- Apply **Partial Indexes** and **Expression Indexes** to reduce index size and improve selectivity.
- Quantify the cost of indexes: **Write Amplification**, page splits, and maintenance overhead.
- Execute hands-on performance labs using `EXPLAIN (ANALYZE, BUFFERS)` to diagnose indexing bugs.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-btree-internals.md](01-btree-internals.md) | B-Tree page layout, search traversal, write amplification |
| [02-composite-and-covering-indexes.md](02-composite-and-covering-indexes.md) | Column ordering, leftmost prefix rule, covering indexes with `INCLUDE` |
| [03-specialized-indexes.md](03-specialized-indexes.md) | Partial indexes, expression indexes, Hash, GIN, BRIN |
| [labs/lab-01-missing-index.md](labs/lab-01-missing-index.md) | Lab: Sequential scan vs B-Tree index scan measurement |
| [labs/lab-02-composite-ordering.md](labs/lab-02-composite-ordering.md) | Lab: Correct vs inverted composite column ordering |
