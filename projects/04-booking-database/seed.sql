INSERT INTO proj_rooms (room_number, room_type, base_price) VALUES
('101', 'DELUXE', 5000.00),
('102', 'DELUXE', 5000.00),
('201', 'SUITE', 12000.00);

INSERT INTO proj_bookings (room_id, customer_name, stay_range) VALUES
(1, 'Alice Chen', daterange('2026-10-01', '2026-10-05', '[)')),
(1, 'Bob Kapoor', daterange('2026-10-06', '2026-10-10', '[)')),
(3, 'David Nakamura', daterange('2026-10-01', '2026-10-07', '[)'));
