-- ============================================================
-- E-Commerce Dataset: Deterministic Seed Data (Development)
-- PostgreSQL 18.6 | sql-interview-preparation
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- CUSTOMERS (12 rows — mix of active, no-orders, multi-orders)
-- ────────────────────────────────────────────────────────────
INSERT INTO customers (email, first_name, last_name, phone, created_at) VALUES
    ('alice.chen@example.com',     'Alice',   'Chen',      '+91-9876543210', '2025-01-15 08:00:00+00'),
    ('bob.kapoor@example.com',     'Bob',     'Kapoor',    '+91-9123456789', '2025-02-20 10:30:00+00'),
    ('carol.lima@example.com',     'Carol',   'Lima',      '+55-1198765432', '2025-03-05 14:00:00+00'),
    ('david.nakamura@example.com', 'David',   'Nakamura',  '+81-9012345678', '2025-04-10 09:00:00+00'),
    ('eva.steele@example.com',     'Eva',     'Steele',    '+44-7911123456', '2025-05-22 11:00:00+00'),
    ('frank.muller@example.com',   'Frank',   'Muller',    '+49-15112345678','2025-06-01 16:00:00+00'),
    ('grace.obi@example.com',      'Grace',   'Obi',       '+234-8012345678','2025-07-18 07:30:00+00'),
    ('henry.park@example.com',     'Henry',   'Park',      '+82-1012345678', '2025-08-03 12:00:00+00'),
    ('irene.ross@example.com',     'Irene',   'Ross',      NULL,             '2025-09-14 13:00:00+00'),
    ('james.wu@example.com',       'James',   'Wu',        '+1-4155552671',  '2025-10-25 15:00:00+00'),
    ('karen.hall@example.com',     'Karen',   'Hall',      '+1-2025551234',  '2025-11-30 09:45:00+00'),
    ('leo.santos@example.com',     'Leo',     'Santos',    NULL,             '2026-01-05 08:00:00+00');
-- Note: leo.santos has NO orders — useful for anti-join exercises

-- ────────────────────────────────────────────────────────────
-- PRODUCTS (8 rows — electronics accessories, various statuses)
-- ────────────────────────────────────────────────────────────
INSERT INTO products (sku, name, description, category, unit_price, status) VALUES
    ('SKU-KBD-01', 'Mechanical Keyboard TKL',    'Tenkeyless, Cherry MX Red',         'Keyboards',   8500.00, 'ACTIVE'),
    ('SKU-MSE-01', 'Wireless Mouse Precision',   'Ergonomic, 3200 DPI, BT 5.0',       'Mice',        2500.00, 'ACTIVE'),
    ('SKU-HUB-01', 'USB-C Hub 7-Port',           '4K HDMI, PD100W, USB 3.2',          'Accessories', 3200.00, 'ACTIVE'),
    ('SKU-STD-01', 'Adjustable Monitor Stand',   'Height/tilt adjustable, 22–34"',    'Accessories', 4100.00, 'ACTIVE'),
    ('SKU-CAM-01', 'Webcam 4K AutoFocus',        '4K 30fps, AI noise cancellation',   'Cameras',     6800.00, 'ACTIVE'),
    ('SKU-SPK-01', 'Desktop Speaker Stereo',     '60W RMS, Bluetooth + 3.5mm',        'Audio',       5200.00, 'ACTIVE'),
    ('SKU-PAD-01', 'XL Desk Pad Premium',        '900×450mm, anti-slip rubber base',  'Accessories',  950.00, 'ACTIVE'),
    ('SKU-CAB-01', 'USB-C Braided Cable 2m',     '240W PD, 40Gbps, 8K@60Hz',          'Cables',       450.00, 'DISCONTINUED');

INSERT INTO inventory (product_id, quantity_on_hand, reorder_level, last_restocked_at) VALUES
    (1,  45, 10, '2026-08-01 00:00:00+00'),
    (2, 180, 20, '2026-08-15 00:00:00+00'),
    (3,  72,  8, '2026-07-20 00:00:00+00'),
    (4,  25,  5, '2026-08-10 00:00:00+00'),
    (5,  60, 10, '2026-08-20 00:00:00+00'),
    (6,  33,  8, '2026-08-05 00:00:00+00'),
    (7, 500, 50, '2026-09-01 00:00:00+00'),
    (8,   0,  0, NULL);  -- Discontinued: no stock

-- ────────────────────────────────────────────────────────────
-- ORDERS (11 rows — various statuses, multi-item, single-item)
-- ────────────────────────────────────────────────────────────
INSERT INTO orders (customer_id, status, shipping_address, subtotal, shipping_cost, total, placed_at) VALUES
    (1, 'DELIVERED', '42 Maple St, Mumbai 400001',       11000.00,     0.00, 11000.00, '2025-11-10 08:00:00+00'),
    (1, 'DELIVERED', '42 Maple St, Mumbai 400001',        3200.00,    99.00,  3299.00, '2026-01-20 10:00:00+00'),
    (1, 'SHIPPED',   '42 Maple St, Mumbai 400001',        6800.00,     0.00,  6800.00, '2026-08-15 14:00:00+00'),
    (2, 'DELIVERED', '7 Park Ave, Delhi 110001',           8500.00,     0.00,  8500.00, '2026-02-14 09:00:00+00'),
    (2, 'CANCELLED', '7 Park Ave, Delhi 110001',           2500.00,    99.00,  2599.00, '2026-05-03 11:00:00+00'),
    (3, 'PENDING',   'Rua XV de Novembro, São Paulo',      4100.00,   199.00,  4299.00, '2026-09-01 06:00:00+00'),
    (4, 'CONFIRMED', '1-1 Shinjuku, Tokyo 160-0022',      12700.00,     0.00, 12700.00, '2026-08-28 02:00:00+00'),
    (5, 'DELIVERED', '10 Downing St, London SW1A',        16050.00,     0.00, 16050.00, '2026-07-04 15:00:00+00'),
    (6, 'DELIVERED', 'Unter den Linden 1, Berlin',        14250.00,     0.00, 14250.00, '2026-06-20 10:00:00+00'),
    (7, 'PENDING',   '23 Marina Rd, Lagos',                5200.00,   499.00,  5699.00, '2026-09-02 07:00:00+00'),
    (9, 'DELIVERED', '456 Oak Lane, Toronto M5V 2H1',      8500.00,     0.00,  8500.00, '2026-07-22 13:00:00+00');
-- Note: customers 8 (Henry), 10 (James), 11 (Karen), 12 (Leo) have no orders — good for anti-join problems

-- ────────────────────────────────────────────────────────────
-- ORDER ITEMS (17 rows — realistic multi-item orders)
-- ────────────────────────────────────────────────────────────
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    -- Order 1: Alice — Keyboard + Mouse (Nov 2025 prices)
    (1, 1, 1, 8500.00),
    (1, 2, 1, 2500.00),
    -- Order 2: Alice — Hub alone
    (2, 3, 1, 3200.00),
    -- Order 3: Alice — Webcam
    (3, 5, 1, 6800.00),
    -- Order 4: Bob — Keyboard
    (4, 1, 1, 8500.00),
    -- Order 5: Bob — CANCELLED Mouse
    (5, 2, 1, 2500.00),
    -- Order 6: Carol — Monitor Stand
    (6, 4, 1, 4100.00),
    -- Order 7: David — Keyboard + Hub + Webcam
    (7, 1, 1, 8500.00),
    (7, 3, 1, 3200.00),
    (7, 5, 1, 1000.00),  -- Was on promo
    -- Order 8: Eva — Full desk setup
    (8, 1, 1, 8500.00),
    (8, 4, 1, 4100.00),
    (8, 6, 1, 3450.00),
    -- Order 9: Frank — Speaker + Pad
    (9, 6, 1, 5200.00),
    (9, 7, 2,  950.00),
    (9, 4, 1, 2200.00),
    -- Order 10: Grace — Speaker
    (10, 6, 1, 5200.00),
    -- Order 11: Irene — Keyboard
    (11, 1, 1, 8500.00);

-- ────────────────────────────────────────────────────────────
-- PAYMENTS (10 rows — covers different statuses including NULL)
-- ────────────────────────────────────────────────────────────
INSERT INTO payments (order_id, amount, method, status, gateway_ref, paid_at) VALUES
    (1,  11000.00, 'CREDIT_CARD', 'COMPLETED', 'GW-CC-2025-001', '2025-11-10 08:05:00+00'),
    (2,   3299.00, 'UPI',         'COMPLETED', 'GW-UPI-2026-002','2026-01-20 10:02:00+00'),
    (3,   6800.00, 'NET_BANKING', 'COMPLETED', 'GW-NB-2026-003', '2026-08-15 14:03:00+00'),
    (4,   8500.00, 'CREDIT_CARD', 'COMPLETED', 'GW-CC-2026-004', '2026-02-14 09:01:00+00'),
    (5,   2599.00, 'DEBIT_CARD',  'REFUNDED',  'GW-DC-2026-005', '2026-05-03 11:02:00+00'),
    (6,   4299.00, 'UPI',         'PENDING',   NULL,             NULL),  -- Order 6 payment not yet processed
    (7,  12700.00, 'WALLET',      'COMPLETED', 'GW-WL-2026-007', '2026-08-28 02:01:00+00'),
    (8,  16050.00, 'CREDIT_CARD', 'COMPLETED', 'GW-CC-2026-008', '2026-07-04 15:02:00+00'),
    (9,  14250.00, 'CREDIT_CARD', 'COMPLETED', 'GW-CC-2026-009', '2026-06-20 10:01:00+00'),
    (10,  5699.00, 'NET_BANKING', 'PENDING',   NULL,             NULL); -- Grace's payment in progress
-- Order 11 (Irene) has NO payment row — useful for anti-join exercises
