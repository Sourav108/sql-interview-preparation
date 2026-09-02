# 03. Multi-Tenant Data Isolation with Row-Level Security (RLS)

## 1. Problem: Multi-Tenant Data Leakage

In a shared multi-tenant SaaS database where all tenants share the same `orders` and `customers` tables, a single missing `WHERE tenant_id = ?` in application code leaks private customer data across tenants.

**Row-Level Security (RLS)** pushes tenant isolation directly into the PostgreSQL storage engine so queries physically *cannot* return rows belonging to other tenants.

---

## 2. Implementing RLS in PostgreSQL

```sql
CREATE TABLE tenant_documents (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id VARCHAR(32) NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL
);

-- 1. Enable RLS on the table
ALTER TABLE tenant_documents ENABLE ROW LEVEL SECURITY;

-- 2. Force RLS for table owners and app roles
ALTER TABLE tenant_documents FORCE ROW LEVEL SECURITY;

-- 3. Define Security Policy based on session variable
CREATE POLICY tenant_isolation_policy ON tenant_documents
    FOR ALL
    TO app_readwrite
    USING (tenant_id = current_setting('app.current_tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.current_tenant_id', true));
```

---

## 3. How the Application Uses RLS

When the backend application handles an incoming HTTP request for Tenant `"acme_corp"`:

```sql
BEGIN;

-- 1. Set the tenant context for this connection session
SET LOCAL app.current_tenant_id = 'acme_corp';

-- 2. Application executes query (WITHOUT needing manual WHERE tenant_id filter!)
SELECT * FROM tenant_documents;
-- PostgreSQL automatically applies the policy and returns ONLY acme_corp rows!

-- 3. Attempting to insert a document for another tenant fails automatically:
INSERT INTO tenant_documents (tenant_id, title, content)
VALUES ('evil_corp', 'Hacked Doc', 'Secret');
-- ERROR: new row violates row-level security policy for table "tenant_documents"

COMMIT;
```
