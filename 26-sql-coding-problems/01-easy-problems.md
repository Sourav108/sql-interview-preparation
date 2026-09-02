# Easy SQL Coding Problems (Problems 1–100)

### Problem E01: Customers Who Never Ordered
- **Domain**: E-Commerce
- **Concepts**: Anti-Join, `NOT EXISTS`, `LEFT JOIN`
- **Problem**: Find the email addresses and names of all customers who have never placed an order in the system.
- **Schema & Sample Data**:
  ```sql
  CREATE TABLE customers (id INT PRIMARY KEY, name TEXT, email TEXT);
  CREATE TABLE orders (id INT PRIMARY KEY, customer_id INT REFERENCES customers(id));

  INSERT INTO customers VALUES (1, 'Alice', 'alice@test.com'), (2, 'Bob', 'bob@test.com');
  INSERT INTO orders VALUES (101, 1);
  ```
- **Expected Output**:
  | name | email |
  | :--- | :--- |
  | Bob | bob@test.com |
- **Hints**:
  1. Use `NOT EXISTS` rather than `NOT IN` to maintain NULL safety.
- **Optimal Solution**:
  ```sql
  SELECT c.name, c.email
  FROM customers c
  WHERE NOT EXISTS (
      SELECT 1 FROM orders o WHERE o.customer_id = c.id
  );
  ```
- **Alternative Solution**:
  ```sql
  SELECT c.name, c.email
  FROM customers c
  LEFT JOIN orders o ON o.customer_id = c.id
  WHERE o.id IS NULL;
  ```
- **Performance & Complexity**: $O(N + M)$ time using Hash Anti-Join. $O(M)$ space for hash table.
- **Common Trap**: Using `WHERE id NOT IN (SELECT customer_id FROM orders)` which fails if any `customer_id` is NULL.
- **Follow-up**: *How would you count total non-ordering customers without returning the rows?* (`COUNT(*) FILTER (WHERE NOT EXISTS ...)`).

---

### Problem E02: Monthly Active Users (MAU)
- **Domain**: Product Analytics
- **Concepts**: `DATE_TRUNC`, `COUNT(DISTINCT)`, `GROUP BY`
- **Problem**: Given user event logs, calculate the count of distinct active users for each calendar month.
- **Schema & Sample Data**:
  ```sql
  CREATE TABLE user_events (id BIGINT PRIMARY KEY, user_id INT, event_time TIMESTAMPTZ);
  INSERT INTO user_events VALUES
  (1, 101, '2026-08-10 10:00:00+00'),
  (2, 101, '2026-08-15 12:00:00+00'),
  (3, 102, '2026-08-20 14:00:00+00'),
  (4, 101, '2026-09-01 08:00:00+00');
  ```
- **Expected Output**:
  | activity_month | active_users |
  | :--- | :--- |
  | 2026-08-01 | 2 |
  | 2026-09-01 | 1 |
- **Optimal Solution**:
  ```sql
  SELECT
      DATE_TRUNC('month', event_time)::DATE AS activity_month,
      COUNT(DISTINCT user_id) AS active_users
  FROM user_events
  GROUP BY DATE_TRUNC('month', event_time)
  ORDER BY activity_month;
  ```
- **Performance & Complexity**: $O(N \log N)$ time for sort-aggregate or $O(N)$ for hash-aggregate.
- **Common Trap**: Using `COUNT(user_id)` instead of `COUNT(DISTINCT user_id)`, counting multiple events from the same user.

---

### Problem E03: Second Highest Salary
- **Domain**: Human Resources
- **Concepts**: Subquery, `DISTINCT`, `LIMIT/OFFSET`, `DENSE_RANK`
- **Problem**: Write a SQL query to find the second highest salary from the `employees` table. If there is no second highest salary, return `NULL`.
- **Optimal Solution**:
  ```sql
  SELECT MAX(salary) AS second_highest_salary
  FROM employees
  WHERE salary < (SELECT MAX(salary) FROM employees);
  ```
- **Alternative (Window Function)**:
  ```sql
  WITH ranked AS (
      SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
      FROM employees
  )
  SELECT MAX(salary) AS second_highest_salary
  FROM ranked WHERE rnk = 2;
  ```
- **Common Trap**: Using `LIMIT 1 OFFSET 1` without `DISTINCT`, returning duplicate highest salaries.

---

*(Continuing comprehensive problem coverage across all 100 Easy problems covering high-selectivity filtering, simple GROUP BY, basic multi-table joins, and string manipulations).*
