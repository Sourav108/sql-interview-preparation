INSERT INTO proj_perf_records (category, score, payload, created_at)
SELECT
    (ARRAY['BRONZE', 'SILVER', 'GOLD', 'PLATINUM'])[floor(random()*4)+1],
    (random()*1000)::int,
    md5(random()::text),
    NOW() - (g || ' minutes')::interval
FROM generate_series(1, 10000) g;

CREATE INDEX idx_proj_perf_cat_score ON proj_perf_records(category, score DESC);
ANALYZE proj_perf_records;
