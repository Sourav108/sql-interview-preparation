-- 1. Query testing partition pruning
EXPLAIN (ANALYZE, BUFFERS)
SELECT device_id, AVG(reading) AS avg_temp
FROM proj_sensor_metrics
WHERE recorded_at >= '2026-09-01 00:00:00+00'
  AND recorded_at <  '2026-09-02 00:00:00+00'
GROUP BY device_id;
