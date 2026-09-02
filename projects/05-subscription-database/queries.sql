-- 1. Monthly Recurring Revenue (MRR) by Plan
SELECT
    p.code AS plan_name,
    COUNT(s.id) AS active_subscriptions,
    SUM(p.monthly_price) AS mrr
FROM proj_subscriptions s
JOIN proj_plans p ON p.id = s.plan_id
WHERE s.status = 'ACTIVE'
GROUP BY p.code;
