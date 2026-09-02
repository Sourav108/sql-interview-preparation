INSERT INTO proj_sensor_metrics (device_id, reading, recorded_at)
SELECT
    (random()*50)::int + 1,
    (random()*100)::numeric(8,2),
    '2026-08-15 00:00:00+00'::timestamptz + (g || ' minutes')::interval
FROM generate_series(1, 1000) g;

INSERT INTO proj_sensor_metrics (device_id, reading, recorded_at)
SELECT
    (random()*50)::int + 1,
    (random()*100)::numeric(8,2),
    '2026-09-01 00:00:00+00'::timestamptz + (g || ' minutes')::interval
FROM generate_series(1, 1000) g;
