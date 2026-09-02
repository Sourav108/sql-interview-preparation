# Mock Interview Round 1: Relational Foundations & SQL Semantics

## 1. Interviewer Opening Prompt
> **Interviewer**: *"Let's start with a fundamentals question. Suppose we have a `customers` table and an `orders` table. A junior engineer wrote a query using `LEFT JOIN` to list all customers with their total spending on completed orders, but customers who never ordered are missing from the report. Can you explain what went wrong and how the database logically evaluates this?"*

---

## 2. Expected Candidate Thinking Process
1. Recognize the classic **Outer-Join Filter Conversion Trap**.
2. Explain the 9-step **Logical Query Processing Order** (`FROM/JOIN` before `WHERE`).
3. Explain 3-valued logic: `NULL = 'COMPLETED'` evaluates to `UNKNOWN` in `WHERE`, filtering out the `NULL`-extended customer rows.
4. Provide the correct query moving the status filter into the `ON` clause, and discuss `COALESCE(SUM(total), 0)`.

---

## 3. Candidate Model Response & Code
> **Candidate**: *"The bug occurs because the engineer placed the filter `WHERE o.status = 'COMPLETED'` in the `WHERE` clause rather than the `ON` clause.*
>
> *In SQL's logical processing order, the `LEFT JOIN` evaluates in Step 2–3, producing `NULL`-extended rows for customers with no matching orders (so `o.status` is `NULL`).*
> *Then in Step 4, the `WHERE` clause evaluates `NULL = 'COMPLETED'`. Under Kleene's three-valued logic, comparison with `NULL` yields `UNKNOWN`. Because the `WHERE` clause only passes rows where the predicate is strictly `TRUE`, all non-ordering customers are discarded, converting the outer join into an inner join.*
>
> *Here is the correct production query:"*

```sql
SELECT
    c.id,
    c.email,
    COALESCE(SUM(o.total), 0.00) AS total_completed_spend
FROM customers c
LEFT JOIN orders o
    ON o.customer_id = c.id
    AND o.status = 'COMPLETED' -- Filter inside ON clause!
GROUP BY c.id, c.email;
```

---

## 4. Interviewer Follow-Up Probes
- **Interviewer**: *"Why did you use `COALESCE(SUM(o.total), 0.00)` instead of just `SUM(o.total)`?"*
  - **Strong Answer**: *"Because aggregate functions ignore NULLs. For customers with zero matching orders, the set of order totals is empty, so `SUM(total)` returns `NULL`, not `0`. In a business reporting API, returning `NULL` for revenue is confusing and can break downstream JSON deserializers."*

---

## 5. Senior vs. Junior Answer Comparison

| Dimension | Junior Candidate Answer | Senior Candidate Answer |
| :--- | :--- | :--- |
| **Explanation** | *"LEFT JOIN is buggy so use a subquery instead."* | Explains logical execution order steps and 3-valued logic truth tables. |
| **Correctness** | Fixes query but forgets `COALESCE`, returning `NULL` spend. | Handles NULLs, empty sets, and groups by primary key cleanly. |
