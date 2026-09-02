CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF EXISTS proj_bookings CASCADE;
DROP TABLE IF EXISTS proj_rooms CASCADE;

CREATE TABLE proj_rooms (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_number VARCHAR(16) NOT NULL UNIQUE,
    room_type VARCHAR(32) NOT NULL,
    base_price NUMERIC(10,2) NOT NULL CHECK (base_price > 0)
);

CREATE TABLE proj_bookings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id BIGINT NOT NULL REFERENCES proj_rooms(id),
    customer_name VARCHAR(100) NOT NULL,
    stay_range DATERANGE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT exclude_room_double_booking
        EXCLUDE USING gist (
            room_id WITH =,
            stay_range WITH &&
        )
        WHERE (status NOT IN ('CANCELLED'))
);
