DROP TABLE IF EXISTS proj_postings CASCADE;
DROP TABLE IF EXISTS proj_journals CASCADE;
DROP TABLE IF EXISTS proj_accounts CASCADE;

CREATE TABLE proj_accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_number VARCHAR(32) NOT NULL UNIQUE,
    owner_name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL, -- ASSET, LIABILITY, REVENUE, EXPENSE
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE proj_journals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reference_id VARCHAR(64) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    posted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE proj_postings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    journal_id BIGINT NOT NULL REFERENCES proj_journals(id),
    account_id BIGINT NOT NULL REFERENCES proj_accounts(id),
    direction VARCHAR(6) NOT NULL CHECK (direction IN ('DEBIT', 'CREDIT')),
    amount NUMERIC(14,2) NOT NULL CHECK (amount > 0)
);

CREATE INDEX idx_proj_postings_acc ON proj_postings(account_id);
