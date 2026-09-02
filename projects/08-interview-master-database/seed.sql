INSERT INTO master_departments VALUES
(1, 'Engineering'), (2, 'Marketing'), (3, 'Finance');

INSERT INTO master_employees (name, department_id, salary, manager_id, hired_at) VALUES
('Priya Sharma', 1, 150000.00, NULL, '2023-01-15'),
('Rohan Kapoor', 1, 120000.00, 1, '2024-03-01'),
('Sneha Reddy', 1, 110000.00, 2, '2024-06-15'),
('Arjun Mehta', 2, 105000.00, 1, '2023-05-10'),
('Meera Nair', 2, 95000.00, 4, '2025-01-20');

INSERT INTO master_transactions (account_id, amount, created_at) VALUES
(101, 1000.00, '2026-09-01 10:00:00+00'),
(101, -250.00, '2026-09-01 14:00:00+00'),
(101, -800.00, '2026-09-02 09:00:00+00'); -- Triggers overdraft (-50.00)

INSERT INTO master_user_logins (user_id, login_date) VALUES
(1, '2026-08-01'), (1, '2026-08-02'), (1, '2026-08-03'), (1, '2026-08-05'),
(2, '2026-08-01'), (2, '2026-08-02');
