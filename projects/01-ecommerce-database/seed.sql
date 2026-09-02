INSERT INTO proj_customers (email, full_name) VALUES
('alice@example.com', 'Alice Chen'),
('bob@example.com', 'Bob Kapoor'),
('carol@example.com', 'Carol Lima');

INSERT INTO proj_products (sku, title, current_price) VALUES
('PROD-KBD-01', 'Mechanical Keyboard', 8500.00),
('PROD-MSE-01', 'Wireless Mouse', 2500.00),
('PROD-MON-01', '4K Monitor', 32000.00);

INSERT INTO proj_inventory (product_id, stock_qty) VALUES
(1, 50),
(2, 100),
(3, 15);

INSERT INTO proj_orders (customer_id, status, total) VALUES
(1, 'DELIVERED', 11000.00),
(2, 'PENDING', 32000.00);

INSERT INTO proj_order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 8500.00),
(1, 2, 1, 2500.00),
(2, 3, 1, 32000.00);

INSERT INTO proj_payments (order_id, idempotency_key, amount, status) VALUES
(1, 'IDEM-PAY-001', 11000.00, 'COMPLETED'),
(2, 'IDEM-PAY-002', 32000.00, 'PENDING');
