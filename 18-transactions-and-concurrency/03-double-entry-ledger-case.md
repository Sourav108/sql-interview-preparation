# 03. Double-Entry Banking Ledger Architecture

## 1. The Financial Invariant

> **In double-entry bookkeeping, money is never created or destroyed out of thin air.**
> Every financial transaction consists of at least two balanced ledger entries:
> $$\sum \text{Debits} = \sum \text{Credits}$$

---

## 2. Production Schema Design

```sql
CREATE TYPE entry_direction AS ENUM ('DEBIT', 'CREDIT');

CREATE TABLE ledger_accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_number VARCHAR(32) NOT NULL UNIQUE,
    account_type VARCHAR(20) NOT NULL, -- ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE journal_entries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reference_id VARCHAR(64) NOT NULL UNIQUE, -- Idempotency key
    description TEXT NOT NULL,
    posted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE ledger_postings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    journal_entry_id BIGINT NOT NULL REFERENCES journal_entries (id) ON DELETE RESTRICT,
    account_id BIGINT NOT NULL REFERENCES ledger_accounts (id) ON DELETE RESTRICT,
    direction entry_direction NOT NULL,
    amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0)
);

CREATE INDEX idx_postings_account ON ledger_postings (account_id, journal_entry_id);
```

---

## 3. Atomic Fund Transfer Transaction

Transfer ₹5,000 from Account 101 to Account 202:

```sql
BEGIN;

-- 1. Create top-level journal transaction (with idempotency key)
INSERT INTO journal_entries (reference_id, description)
VALUES ('TXN-2026-09-02-001', 'Transfer from 101 to 202')
RETURNING id; -- Assume returns id = 42

-- 2. Debit Sender (reduces liability/asset)
INSERT INTO ledger_postings (journal_entry_id, account_id, direction, amount)
VALUES (42, 101, 'DEBIT', 5000.00);

-- 3. Credit Receiver (increases balance)
INSERT INTO ledger_postings (journal_entry_id, account_id, direction, amount)
VALUES (42, 202, 'CREDIT', 5000.00);

-- 4. Invariant Check: Sum of Debits MUST equal Sum of Credits for entry 42
DO $$
DECLARE
    v_debit_sum NUMERIC;
    v_credit_sum NUMERIC;
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO v_debit_sum
    FROM ledger_postings WHERE journal_entry_id = 42 AND direction = 'DEBIT';

    SELECT COALESCE(SUM(amount), 0) INTO v_credit_sum
    FROM ledger_postings WHERE journal_entry_id = 42 AND direction = 'CREDIT';

    IF v_debit_sum <> v_credit_sum THEN
        RAISE EXCEPTION 'Ledger imbalance! Debits (%) != Credits (%)', v_debit_sum, v_credit_sum;
    END IF;
END $$;

COMMIT;
```
