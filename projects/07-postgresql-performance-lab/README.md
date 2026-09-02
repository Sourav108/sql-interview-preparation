# Project 07: PostgreSQL Performance & Tuning Lab

Standalone reproducible performance testing environment for diagnosing index scans, table bloat, and Keyset pagination.

## Quickstart
```bash
psql -U postgres -d sql_interview_db < schema.sql
psql -U postgres -d sql_interview_db < seed.sql
psql -U postgres -d sql_interview_db < queries.sql
```
