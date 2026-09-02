-- 1. Check ledger balance invariant (Debits must equal Credits)
SELECT
    j.id AS journal_id,
    j.reference_id,
    SUM(CASE WHEN p.direction = 'DEBIT' THEN p.amount ELSE 0 END) AS total_debits,
    SUM(CASE WHEN p.direction = 'CREDIT' THEN p.amount ELSE 0 END) AS total_credits
FROM proj_journals j
JOIN proj_postings p ON p.journal_id = j.id
GROUP BY j.id, j.reference_id
HAVING SUM(CASE WHEN p.direction = 'DEBIT' THEN p.amount ELSE 0 END) <>
       SUM(CASE WHEN p.direction = 'CREDIT' THEN p.amount ELSE 0 END);

-- 2. Net account balance
SELECT
    a.account_number,
    a.owner_name,
    SUM(CASE WHEN p.direction = 'CREDIT' THEN p.amount ELSE -p.amount END) AS balance
FROM proj_accounts a
JOIN proj_postings p ON p.account_id = a.id
GROUP BY a.id, a.account_number, a.owner_name;
