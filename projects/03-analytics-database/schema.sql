DROP TABLE IF EXISTS proj_events CASCADE;

CREATE TABLE proj_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
    event_name VARCHAR(50) NOT NULL,
    properties JSONB NOT NULL DEFAULT '{}',
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_proj_events_user_time ON proj_events(user_id, occurred_at ASC);
CREATE INDEX idx_proj_events_props ON proj_events USING GIN(properties);
