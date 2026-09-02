# Database Design Case 2: Double-Entry Core Banking Ledger

## 1. Requirements & Invariants
- **Core Invariant**: $\sum \text{Debits} = \sum \text{Credits}$ across all journal postings.
- **Auditability**: Complete immutability; **zero `UPDATE` or `DELETE` allowed** on financial ledger rows. Corrections must be applied as offsetting reversal journal entries.
- **Scale**: 5,000 QPS transfer transactions, sub-50ms latency SLA.

---

## 2. Relational Schema DDL

```sql
CREATE TYPE account_classification AS ENUM ('ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE');
CREATE TYPE entry_direction AS ENUM ('DEBIT', 'CREDIT');

CREATE TABLE accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_number VARCHAR(32) NOT NULL UNIQUE,
    customer_id BIGINT NOT NULL,
    classification account_classification NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE journals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    idempotency_key VARCHAR(64) NOT NULL UNIQUE,
    narration TEXT NOT NULL,
    posted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE postings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    journal_id BIGINT NOT NULL REFERENCES journals (id),
    account_id BIGINT NOT NULL REFERENCES accounts (id),
    direction entry_direction NOT NULL,
    amount NUMERIC(16,4) NOT NULL CHECK (amount > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_postings_account_created ON postings (account_id, created_at DESC);
```

---

## 3. Real-Time Balance Query with Daily Balance Snapshots

Calculating account balance across 500,000 historical postings:

```sql
-- Fast read query leveraging daily closing snapshots
SELECT
    a.account_number,
    COALESCE(s.closing_balance, 0) +
    COALESCE(SUM(
        CASE
            WHEN p.direction = 'CREDIT' THEN p.amount
            WHEN p.direction = 'DEBIT'  THEN -p.amount
        END
    ), 0) AS current_balance
FROM accounts a
LEFT JOIN daily_account_snapshots s
    ON s.account_id = a.id AND s.snapshot_date = CURRENT_DATE - 1
LEFT JOIN postings p
    ON p.account_id = a.id AND p.created_at >= CURRENT_DATE
WHERE a.id = 101
GROUP BY a.account_number, s.closing_balance;
```
