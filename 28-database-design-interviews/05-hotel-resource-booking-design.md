# Database Design Case 5: Hotel & Conference Resource Booking

## 1. Requirements
- Customers search room availability for date ranges (`[check_in, check_out)`).
- Customers reserve rooms; **strictly zero double-booking** allowed across concurrent users.
- Support dynamic nightly pricing and instant non-overlapping range validation.

---

## 2. Schema DDL with PostgreSQL Exclusion Constraints

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE rooms (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_number VARCHAR(16) NOT NULL UNIQUE,
    room_type VARCHAR(32) NOT NULL, -- DELUXE, SUITE, STANDARD
    base_price_cents INT NOT NULL CHECK (base_price_cents > 0)
);

CREATE TABLE bookings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id BIGINT NOT NULL REFERENCES rooms (id),
    customer_id BIGINT NOT NULL,
    stay_range DATERANGE NOT NULL, -- [check_in, check_out) date range
    total_price_cents INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Database-level non-overlapping constraint!
    CONSTRAINT exclude_double_booking
        EXCLUDE USING gist (
            room_id WITH =,
            stay_range WITH &&
        )
        WHERE (status NOT IN ('CANCELLED'))
);
```

---

## 3. High-Performance Room Availability Search Query

Find all available DELUXE rooms for the date range `[2026-10-01, 2026-10-05)`:

```sql
SELECT r.id, r.room_number, r.base_price_cents
FROM rooms r
WHERE r.room_type = 'DELUXE'
  AND NOT EXISTS (
      -- Anti-Join on overlapping active bookings
      SELECT 1 FROM bookings b
      WHERE b.room_id = r.id
        AND b.status NOT IN ('CANCELLED')
        AND b.stay_range && daterange('2026-10-01', '2026-10-05', '[)')
  );
```
