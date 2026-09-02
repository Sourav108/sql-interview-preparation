-- 1. Employees earning more than their managers
SELECT e.name AS employee, e.salary, m.name AS manager, m.salary AS manager_salary
FROM master_employees e
JOIN master_employees m ON m.id = e.manager_id
WHERE e.salary > m.salary;

-- 2. Detect running overdrafts
SELECT
    account_id,
    created_at,
    amount,
    SUM(amount) OVER (PARTITION BY account_id ORDER BY created_at ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance
FROM master_transactions;
