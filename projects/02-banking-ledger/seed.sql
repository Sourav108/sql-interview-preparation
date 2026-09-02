INSERT INTO proj_accounts (account_number, owner_name, type) VALUES
('ACC-101', 'Alice Savings', 'LIABILITY'),
('ACC-102', 'Bob Savings', 'LIABILITY'),
('ACC-FEE', 'Bank Fee Income', 'REVENUE');

-- Transfer 1000 from Alice to Bob + 10 fee
INSERT INTO proj_journals (reference_id, description) VALUES
('TXN-001', 'Transfer Alice to Bob with fee');

INSERT INTO proj_postings (journal_id, account_id, direction, amount) VALUES
(1, 1, 'DEBIT', 1010.00),
(1, 2, 'CREDIT', 1000.00),
(1, 3, 'CREDIT', 10.00);
