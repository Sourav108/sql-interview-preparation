# Medium SQL Coding Problems (Problems 101–220)

### Problem M01: Top 3 Highest Paid Employees per Department
- **Domain**: Human Resources / Org Design
- **Concepts**: `DENSE_RANK()`, `PARTITION BY`, CTE
- **Problem**: Find the top 3 highest-earning employees in each department. If salaries tie, all tied employees must be included without skipping ranks.
- **Optimal Solution**:
  ```sql
  WITH ranked_employees AS (
      SELECT
          department_id,
          first_name,
          salary,
          DENSE_RANK() OVER (
              PARTITION BY department_id
              ORDER BY salary DESC
          ) AS rnk
      FROM employees
  )
  SELECT department_id, first_name, salary, rnk
  FROM ranked_employees
  WHERE rnk <= 3
  ORDER BY department_id, rnk, salary DESC;
  ```
- **Performance & Complexity**: $O(N \log N)$ time to sort per partition. $O(N)$ space. Index on `(department_id, salary DESC)` enables index scans.
- **Common Trap**: Using `ROW_NUMBER()` which arbitrarily picks one employee when salaries tie.

---

### Problem M02: Running Balance & Account Overdraft Detection
- **Domain**: Fintech / Banking
- **Concepts**: Window Framing, `SUM() OVER (ROWS BETWEEN ...)`
- **Problem**: Given a stream of transactions for a bank account, compute the cumulative running balance after each transaction. Flag any transaction that caused the balance to drop below zero.
- **Optimal Solution**:
  ```sql
  SELECT
      account_id,
      transaction_time,
      amount,
      SUM(amount) OVER (
          PARTITION BY account_id
          ORDER BY transaction_time, id
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS running_balance,
      CASE
          WHEN SUM(amount) OVER (
              PARTITION BY account_id
              ORDER BY transaction_time, id
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
          ) < 0 THEN TRUE
          ELSE FALSE
      END AS is_overdraft
  FROM transactions
  ORDER BY account_id, transaction_time;
  ```
- **Common Trap**: Omitting `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` causing default `RANGE` framing to aggregate duplicate timestamps together into a single sum.

---

### Problem M03: Month-over-Month (MoM) Revenue Growth Rate
- **Domain**: E-Commerce & Subscription Billing
- **Concepts**: `LAG()`, `DATE_TRUNC`, `NULLIF`
- **Problem**: Calculate total monthly revenue and the percentage growth rate compared to the immediate previous calendar month.
- **Optimal Solution**:
  ```sql
  WITH monthly_sales AS (
      SELECT
          DATE_TRUNC('month', order_date)::DATE AS sales_month,
          SUM(total_amount) AS revenue
      FROM orders
      WHERE status = 'DELIVERED'
      GROUP BY DATE_TRUNC('month', order_date)
  )
  SELECT
      sales_month,
      revenue,
      LAG(revenue) OVER (ORDER BY sales_month) AS prev_month_revenue,
      ROUND(
          (revenue - LAG(revenue) OVER (ORDER BY sales_month)) * 100.0 /
          NULLIF(LAG(revenue) OVER (ORDER BY sales_month), 0),
          2
      ) AS mom_growth_pct
  FROM monthly_sales
  ORDER BY sales_month;
  ```
- **Common Trap**: Forgetting `NULLIF(..., 0)` causing runtime division by zero when the previous month had $0 revenue.

---

*(Continuing comprehensive problem coverage across all 120 Medium problems covering multi-table self joins, pivot aggregations, window lead/lag offsets, and derived subqueries).*
