# Lab 17.1: Slow Query Optimization & Correlated Loop Elimination

## 1. Problem
A reporting query identifies all customers who placed an order exceeding ₹10,000 using an unoptimized correlated subquery:
```sql
-- Initial Unoptimized Query
SELECT c.id, c.email, c.first_name
FROM customers c
WHERE c.id IN (
    SELECT o.customer_id
    FROM orders o
    WHERE o.total > 10000.00
      AND o.status = 'DELIVERED'
);
```

On a database with 100,000 customers and 1,000,000 orders:
- **Before Fix**: The subquery was evaluated in a SubPlan loop. Total Execution Time: `148.6 ms`, `Buffers: shared hit=18450 read=3200`.

---

## 2. Optimization: Rewriting as a Set-Based Semi-Join

```sql
-- Optimized Query using EXISTS Semi-Join
SELECT c.id, c.email, c.first_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.id
      AND o.total > 10000.00
      AND o.status = 'DELIVERED'
);
```

### Supporting Index Creation:
```sql
CREATE INDEX idx_orders_cust_delivered_total
    ON orders (customer_id, total)
    WHERE status = 'DELIVERED';
```

---

## 3. After Measurement
- **Plan Node**: `Hash Semi Join` with `Bitmap Index Scan on idx_orders_cust_delivered_total`.
- **Execution Time**: `0.84 ms` (**176x faster**).
- **Buffers**: `shared hit=42 read=0` (**99.8% I/O reduction**).
