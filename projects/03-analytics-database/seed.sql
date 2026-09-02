INSERT INTO proj_events (user_id, event_name, properties, occurred_at) VALUES
(101, 'page_view', '{"url": "/home"}', '2026-09-02 10:00:00+00'),
(101, 'view_item', '{"item_id": 42}', '2026-09-02 10:05:00+00'),
(101, 'add_to_cart', '{"item_id": 42}', '2026-09-02 10:10:00+00'),
(101, 'checkout', '{"amount": 8500}', '2026-09-02 10:15:00+00'),
(102, 'page_view', '{"url": "/home"}', '2026-09-02 11:00:00+00'),
(102, 'view_item', '{"item_id": 99}', '2026-09-02 11:45:00+00'); -- New session (>30m)
