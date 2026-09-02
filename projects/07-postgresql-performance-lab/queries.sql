-- Benchmark Index Scan vs Bitmap Scan
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM proj_perf_records
WHERE category = 'GOLD' AND score > 800
ORDER BY score DESC
LIMIT 50;
