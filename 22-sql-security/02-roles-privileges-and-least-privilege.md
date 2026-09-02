# 02. PostgreSQL Roles, Privileges & Principle of Least Privilege

## 1. Principle of Least Privilege in Database Design

**Rule**: *An application database connection should only have the minimum permissions strictly necessary to execute its intended business functions.*

Never connect backend microservices using the `postgres` superuser account!

---

## 2. Standard Production Role Hierarchy

```sql
-- 1. Create Application Role (No superuser, cannot create databases)
CREATE ROLE app_readwrite WITH LOGIN PASSWORD 'secure_app_pwd_2026';

-- 2. Grant access to specific schema only
GRANT USAGE ON SCHEMA public TO app_readwrite;

-- 3. Grant table DML permissions (NO DDL: no DROP TABLE, no ALTER TABLE)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_readwrite;

-- 4. Grant sequence usage for auto-incrementing IDs
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_readwrite;

-- 5. Set default privileges for future tables created by migrations
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_readwrite;
```

---

## 3. Read-Only Analytics Role

```sql
CREATE ROLE analytics_readonly WITH LOGIN PASSWORD 'readonly_pwd_2026';

GRANT USAGE ON SCHEMA public TO analytics_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_readonly;

-- Enforce read-only transaction state at session level
ALTER ROLE analytics_readonly SET default_transaction_read_only = on;
```
