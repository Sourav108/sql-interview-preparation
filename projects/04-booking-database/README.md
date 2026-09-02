# Project 04: Hotel & Resource Booking Engine

Hotel room reservation database leveraging PostgreSQL Exclusion Constraints (`GiST`) for zero double-bookings.

## Quickstart
```bash
psql -U postgres -d sql_interview_db < schema.sql
psql -U postgres -d sql_interview_db < seed.sql
psql -U postgres -d sql_interview_db < queries.sql
```
