# 02. PostgreSQL Exclusion Constraints (`EXCLUDE USING gist`)

## 1. Problem: The Overlapping Booking Challenge

Standard `UNIQUE` and `CHECK` constraints operate on simple scalar values or row-level predicates. But what if a business requirement dictates:
> *"No two bookings for the same conference room or hotel room may overlap in time."*

Traditional approaches fail under concurrency:
```sql
-- Application checks:
SELECT COUNT(*) FROM room_bookings
WHERE room_id = 101 AND check_in < :new_out AND check_out > :new_in;
-- If count == 0, insert...
-- ❌ RACE CONDITION: Two concurrent threads execute the SELECT simultaneously,
-- both receive count = 0, and both INSERT overlapping bookings!
```

---

## 2. The Solution: `EXCLUDE USING gist`

PostgreSQL provides **Exclusion Constraints**, which enforce that if any two rows are compared on specified columns using specified operators, at least one comparison operator returns `FALSE`.

```sql
-- Enable btree_gist extension for combining scalar equality (=) with range overlaps (&&)
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE room_bookings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id INT NOT NULL,
    booking_range TSRANGE NOT NULL, -- timestamp range: [start, end)
    customer_id BIGINT NOT NULL,

    -- Enforce: No two rows with the same room_id (=) can have overlapping ranges (&&)
    CONSTRAINT exclude_overlapping_room_bookings
        EXCLUDE USING gist (
            room_id WITH =,
            booking_range WITH &&
        )
);
```

---

## 3. Practical Demonstration

```sql
-- Booking 1: Room 101 from 10:00 to 12:00
INSERT INTO room_bookings (room_id, booking_range, customer_id)
VALUES (101, tsrange('2026-09-02 10:00:00', '2026-09-02 12:00:00', '[)'), 1);
-- ✅ Succeeds

-- Booking 2: Room 101 from 11:30 to 13:00 (Overlaps with Booking 1)
INSERT INTO room_bookings (room_id, booking_range, customer_id)
VALUES (101, tsrange('2026-09-02 11:30:00', '2026-09-02 13:00:00', '[)'), 2);
-- ❌ Fails with error:
-- ERROR: conflicting key value violates exclusion constraint "exclude_overlapping_room_bookings"
-- DETAIL: Key (room_id, booking_range)=(101, ["2026-09-02 11:30:00","2026-09-02 13:00:00"))
-- conflicts with existing key (room_id, booking_range)=(101, ["2026-09-02 10:00:00","2026-09-02 12:00:00")).

-- Booking 3: Room 102 from 11:30 to 13:00 (Different room)
INSERT INTO room_bookings (room_id, booking_range, customer_id)
VALUES (102, tsrange('2026-09-02 11:30:00', '2026-09-02 13:00:00', '[)'), 3);
-- ✅ Succeeds
```

---

## 4. Range Types & Operators in PostgreSQL

| Range Type | Underlying Element Type |
| :--- | :--- |
| `INT4RANGE` / `INT8RANGE` | Integer spans (e.g. discount tiers) |
| `NUMRANGE` | Numeric spans (e.g. salary bands) |
| `DATERANGE` | Calendar date ranges `[2026-09-01, 2026-09-05)` |
| `TSRANGE` / `TSTZRANGE` | Timestamps with/without time zone |

### Key Range Operators
- `&&` : Overlaps (true if ranges share any common point)
- `@>` : Contains element or range (`tsrange @> '2026-09-02 10:30:00'`)
- `<@` : Contained by
- `-|-` : Adjacent (ranges meet at boundary without overlapping)

---

## 5. Interview Trade-offs

| Criterion | Exclusion Constraint (`GiST`) | Application-Layer Pessimistic Lock |
| :--- | :--- | :--- |
| **Concurrency Safety** | 100% database-guaranteed via index locks | Requires explicit `SELECT ... FOR UPDATE` on room row |
| **Performance Overhead** | Small GiST index maintenance cost on writes | Database lock contention on parent room record |
| **Database Portability** | PostgreSQL specific feature | Portable across MySQL, Oracle, SQL Server |
