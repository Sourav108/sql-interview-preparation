-- 1. Clickstream Sessionization (30 min inactivity window)
WITH deltas AS (
    SELECT
        user_id,
        occurred_at,
        event_name,
        CASE
            WHEN occurred_at - LAG(occurred_at) OVER (PARTITION BY user_id ORDER BY occurred_at) > INTERVAL '30 minutes'
                 OR LAG(occurred_at) OVER (PARTITION BY user_id ORDER BY occurred_at) IS NULL
            THEN 1 ELSE 0
        END AS is_new_session
    FROM proj_events
)
SELECT
    user_id,
    SUM(is_new_session) OVER (PARTITION BY user_id ORDER BY occurred_at ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS session_id,
    event_name,
    occurred_at
FROM deltas;
