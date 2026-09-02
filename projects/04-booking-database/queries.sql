-- 1. Find all DELUXE rooms available for [2026-10-02, 2026-10-04)
SELECT r.id, r.room_number, r.room_type, r.base_price
FROM proj_rooms r
WHERE r.room_type = 'DELUXE'
  AND NOT EXISTS (
      SELECT 1 FROM proj_bookings b
      WHERE b.room_id = r.id
        AND b.status <> 'CANCELLED'
        AND b.stay_range && daterange('2026-10-02', '2026-10-04', '[)')
  );
-- Expected: Room 102 (Room 101 is booked by Alice)
