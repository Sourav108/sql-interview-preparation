# Lab 24.2: Connection Exhaustion & PgBouncer Connection Pooling

## 1. Problem
Under a traffic spike, 50 microservice instances each configure a connection pool of 20 connections ($50 \times 20 = 1,000$ connections). PostgreSQL hits `FATAL: remaining connection slots are reserved for non-superuser connections` (when `max_connections = 100`).

---

## 2. Investigating Connection States

```sql
SELECT
    state,
    COUNT(*) AS connection_count
FROM pg_stat_activity
GROUP BY state;
```
*Result shows 95 connections `idle` and 5 active, but new connections are rejected.*

---

## 3. The Solution: PgBouncer in Transaction Pooling Mode

Instead of each application thread holding an exclusive dedicated PostgreSQL OS process connection:
1. Deploy **PgBouncer** connection pooler in front of PostgreSQL.
2. Configure **Transaction Pooling Mode** (`pool_mode = transaction`).
3. Application servers connect to PgBouncer (supporting 10,000+ client connections).
4. PgBouncer multiplexes active transactions across a small, highly tuned backend pool of only 20–50 real PostgreSQL connections.

### Benefits:
- Eliminates connection handshake and memory overhead ($10\text{MB}$ per backend process reduced to a single shared queue).
- CPU context switching drops by $>80\%$.
- Query throughput increases by $>3\times$ under heavy concurrency.
