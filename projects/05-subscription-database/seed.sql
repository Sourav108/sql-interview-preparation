INSERT INTO proj_tenants (id, name) VALUES
('tenant_acme', 'Acme Corp'),
('tenant_globex', 'Globex Inc');

INSERT INTO proj_plans (code, monthly_price) VALUES
('STARTER', 29.00),
('ENTERPRISE', 499.00);

INSERT INTO proj_subscriptions (tenant_id, plan_id, status, period_end) VALUES
('tenant_acme', 1, 'ACTIVE', '2026-09-02 23:59:59+00'),
('tenant_globex', 2, 'ACTIVE', '2026-09-30 23:59:59+00');

INSERT INTO proj_invoices (tenant_id, subscription_id, amount, status, due_date) VALUES
('tenant_acme', 1, 29.00, 'PAID', '2026-08-02'),
('tenant_globex', 2, 499.00, 'PAID', '2026-08-30');
