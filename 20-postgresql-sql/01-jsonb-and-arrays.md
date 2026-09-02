# 01. PostgreSQL `JSONB` and Native Array Types

## 1. `JSON` vs. `JSONB`

PostgreSQL offers two JSON data types:

| Feature | `JSON` (Text Storage) | `JSONB` (Deconstructed Binary) |
| :--- | :--- | :--- |
| **Storage Format** | Exact verbatim text copy (preserves whitespace & key order) | Parsed binary format (strips whitespace, deduplicates keys) |
| **Write Performance**| Slightly faster (raw text store) | Slightly slower (must parse JSON into binary tree) |
| **Read Performance** | Slow (must re-parse text on every query) | **Fast** (direct binary field traversal) |
| **Indexing** | No specialized GIN index support | **Supports GIN indexes** (instant sub-object lookups) |
| **Recommendation** | Rare (logging exact raw text) | **Default choice for all application JSON storage** |

---

## 2. Querying `JSONB` with Native Operators

```sql
CREATE TABLE audit_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO audit_events (event_type, payload) VALUES
('USER_LOGIN', '{"user_id": 42, "ip": "192.168.1.1", "device": {"os": "macOS", "browser": "Chrome"}, "roles": ["ADMIN", "USER"]}');

-- 1. Extract JSON object field as JSONB (->)
SELECT payload -> 'device' FROM audit_events;
-- Returns: '{"os": "macOS", "browser": "Chrome"}'::jsonb

-- 2. Extract JSON field as scalar TEXT (->>)
SELECT payload -> 'device' ->> 'os' FROM audit_events;
-- Returns: 'macOS' (text)

-- 3. Check JSON Key existence (?)
SELECT * FROM audit_events WHERE payload ? 'ip';

-- 4. JSON Containment / Sub-document matching (@>)
SELECT * FROM audit_events WHERE payload @> '{"user_id": 42}';
SELECT * FROM audit_events WHERE payload @> '{"device": {"os": "macOS"}}';
```

---

## 3. GIN Indexing for JSONB

```sql
-- 1. Standard GIN index supporting all containment (@>), key existence (?), and array operators
CREATE INDEX idx_audit_payload_gin ON audit_events USING GIN (payload);

-- 2. Specialized jsonb_path_ops (3x smaller index, supports ONLY containment @>)
CREATE INDEX idx_audit_payload_path_ops ON audit_events USING GIN (payload jsonb_path_ops);

-- Query using GIN index seek:
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM audit_events WHERE payload @> '{"user_id": 42}';
-- Plan: Bitmap Index Scan on idx_audit_payload_gin
```

---

## 4. PostgreSQL Native Array Types

```sql
CREATE TABLE posts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL,
    tags TEXT[] NOT NULL DEFAULT '{}' -- Array of strings
);

INSERT INTO posts (title, tags) VALUES
('PostgreSQL Indexing Guide', ARRAY['postgres', 'sql', 'performance']),
('Java Microservices', ARRAY['java', 'spring-boot', 'backend']);

-- 1. Array Containment (@>)
SELECT * FROM posts WHERE tags @> ARRAY['postgres'];

-- 2. Array Overlap (&& - contains ANY of the given elements)
SELECT * FROM posts WHERE tags && ARRAY['spring-boot', 'docker'];

-- 3. GIN Index on Array Column
CREATE INDEX idx_posts_tags_gin ON posts USING GIN (tags);
```
