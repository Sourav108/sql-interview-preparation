DROP TABLE IF EXISTS proj_invoices CASCADE;
DROP TABLE IF EXISTS proj_subscriptions CASCADE;
DROP TABLE IF EXISTS proj_plans CASCADE;
DROP TABLE IF EXISTS proj_tenants CASCADE;

CREATE TABLE proj_tenants (
    id VARCHAR(32) PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE proj_plans (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    monthly_price NUMERIC(10,2) NOT NULL CHECK (monthly_price >= 0)
);

CREATE TABLE proj_subscriptions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id VARCHAR(32) NOT NULL REFERENCES proj_tenants(id),
    plan_id BIGINT NOT NULL REFERENCES proj_plans(id),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    period_end TIMESTAMPTZ NOT NULL
);

CREATE TABLE proj_invoices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id VARCHAR(32) NOT NULL REFERENCES proj_tenants(id),
    subscription_id BIGINT REFERENCES proj_subscriptions(id),
    amount NUMERIC(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PAID',
    due_date DATE NOT NULL
);
