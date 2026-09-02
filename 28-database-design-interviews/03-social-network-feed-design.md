# Database Design Case 3: Social Activity Feed & Graph Network

## 1. Requirements
- Users follow other users; users publish posts with media.
- Users view an activity feed of posts from people they follow, ordered by `created_at DESC` with Keyset pagination.
- **Scale**: 500 million users, 50,000 QPS feed reads, 5,000 QPS post writes.

---

## 2. Schema DDL

```sql
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE follows (
    follower_id BIGINT NOT NULL REFERENCES users (id),
    followee_id BIGINT NOT NULL REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, followee_id),
    CONSTRAINT chk_no_self_follow CHECK (follower_id <> followee_id)
);

CREATE INDEX idx_follows_followee ON follows (followee_id, follower_id);

CREATE TABLE posts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    author_id BIGINT NOT NULL REFERENCES users (id),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_posts_author_created ON posts (author_id, created_at DESC, id DESC);
```

---

## 3. Feed Generation Query (Fanout-on-Read with Keyset Seek)

```sql
SELECT p.id, p.author_id, u.username, p.content, p.created_at
FROM follows f
JOIN posts p ON p.author_id = f.followee_id
JOIN users u ON u.id = p.author_id
WHERE f.follower_id = :current_user_id
  AND (p.created_at, p.id) < (:last_seen_created_at, :last_seen_post_id)
ORDER BY p.created_at DESC, p.id DESC
LIMIT 20;
```

---

## 4. Architectural Scaling Strategy
- **Standard Users (< 5,000 followers)**: Fanout-on-Read using the above optimized composite index query.
- **Celebrity Accounts (> 1M followers)**: Fanout-on-Write into Redis feed caches to avoid generating millions of fanout DB writes on every post.
