DROP TABLE IF EXISTS proj_perf_records CASCADE;

CREATE TABLE proj_perf_records (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category VARCHAR(20) NOT NULL,
    score INT NOT NULL,
    payload TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);
