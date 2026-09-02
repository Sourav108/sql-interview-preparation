DROP TABLE IF EXISTS master_user_logins CASCADE;
DROP TABLE IF EXISTS master_transactions CASCADE;
DROP TABLE IF EXISTS master_employees CASCADE;
DROP TABLE IF EXISTS master_departments CASCADE;

CREATE TABLE master_departments (
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE master_employees (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department_id INT REFERENCES master_departments(id),
    salary NUMERIC(10,2) NOT NULL,
    manager_id BIGINT REFERENCES master_employees(id),
    hired_at DATE NOT NULL
);

CREATE TABLE master_transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id INT NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE master_user_logins (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
    login_date DATE NOT NULL
);
