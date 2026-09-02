# Project 06: High-Throughput Partitioned Event Store

Time-series event storage engine with declarative table partitioning, BRIN indexes, and fast data lifecycle pruning.

## Quickstart
```bash
psql -U postgres -d sql_interview_db < schema.sql
psql -U postgres -d sql_interview_db < seed.sql
psql -U postgres -d sql_interview_db < queries.sql
```
