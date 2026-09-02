DROP TABLE IF EXISTS proj_sensor_metrics CASCADE;

CREATE TABLE proj_sensor_metrics (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    device_id INT NOT NULL,
    reading NUMERIC(8,2) NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

CREATE TABLE proj_sensor_2026_08 PARTITION OF proj_sensor_metrics
    FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00');

CREATE TABLE proj_sensor_2026_09 PARTITION OF proj_sensor_metrics
    FOR VALUES FROM ('2026-09-01 00:00:00+00') TO ('2026-10-01 00:00:00+00');

CREATE INDEX idx_sensor_brin_time ON proj_sensor_metrics USING BRIN (recorded_at);
