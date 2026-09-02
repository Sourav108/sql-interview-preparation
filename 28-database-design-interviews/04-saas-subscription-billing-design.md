# Database Design Case 4: Multi-Tenant SaaS Subscription & Billing

## 1. Requirements
- Tenants subscribe to tiered plans (e.g. Free, Pro, Enterprise) with monthly or annual billing cycles.
- Support plan upgrades/downgrades with mid-cycle proration credits.
- Automatic recurring invoice generation and multi-tenant Row-Level Security (RLS) isolation.

---

## 2. Schema DDL

```sql
CREATE TYPE billing_interval AS ENUM ('MONTHLY', 'YEARLY');
CREATE TYPE subscription_status AS ENUM ('TRIALING', 'ACTIVE', 'PAST_DUE', 'CANCELED');
CREATE TYPE invoice_status AS ENUM ('DRAFT', 'OPEN', 'PAID', 'VOID', 'UNCOLLECTIBLE');

CREATE TABLE tenants (
    id VARCHAR(32) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE plans (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    price_cents INT NOT NULL CHECK (price_cents >= 0),
    interval billing_interval NOT NULL
);

CREATE TABLE subscriptions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id VARCHAR(32) NOT NULL REFERENCES tenants (id),
    plan_id BIGINT NOT NULL REFERENCES plans (id),
    status subscription_status NOT NULL DEFAULT 'ACTIVE',
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE invoices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id VARCHAR(32) NOT NULL REFERENCES tenants (id),
    subscription_id BIGINT REFERENCES subscriptions (id),
    amount_due_cents INT NOT NULL CHECK (amount_due_cents >= 0),
    amount_paid_cents INT NOT NULL DEFAULT 0,
    status invoice_status NOT NULL DEFAULT 'DRAFT',
    due_date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 3. Recurring Billing Automation Query
Find all active subscriptions expiring today that require automatic invoice generation:

```sql
SELECT
    s.id AS subscription_id,
    s.tenant_id,
    p.price_cents,
    s.current_period_end
FROM subscriptions s
JOIN plans p ON p.id = s.plan_id
WHERE s.status = 'ACTIVE'
  AND s.current_period_end <= NOW()
  AND NOT EXISTS (
      -- Prevent duplicate invoice generation (Idempotency)
      SELECT 1 FROM invoices i
      WHERE i.subscription_id = s.id
        AND i.created_at >= s.current_period_end - INTERVAL '1 day'
  )
FOR UPDATE SKIP LOCKED;
```
