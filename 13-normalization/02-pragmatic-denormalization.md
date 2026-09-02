# 02. Pragmatic Denormalization and Materialized Views

## 1. Why Normalization Is Not Always the End Goal

While 3NF/BCNF eliminates redundancy and write anomalies in transactional OLTP databases, strict normalization has a real performance cost:
- **Join Amplification**: A single API endpoint fetching order details may require joining 7 tables (`orders`, `order_items`, `customers`, `products`, `discounts`, `shipping_addresses`, `billing_addresses`).
- **Aggregations at Scale**: Calculating customer lifetime value or store revenue across 500 million transaction rows at request time is computationally prohibitive.

---

## 2. When to Denormalize: The Strategic Rule

Denormalize **only when measured read performance bottlenecks justify the cost of write synchronization**.

```
                           Read vs Write Trade-off
 ─────────────────────────────────────────────────────────────────────────────
 3NF Normalized Schema                          Pragmatic Denormalized Schema
 - Fast, simple INSERT/UPDATE                   - Faster SELECTs (fewer joins)
 - Minimum storage & zero anomalies             - Precomputed aggregates
 - Expensive complex multi-table joins          - Higher write amplification & drift risk
```

### Common Patterns of Controlled Denormalization
1. **Precomputed Aggregates**: Storing `orders.total_amount` and `orders.item_count` rather than computing `SUM(quantity * unit_price)` on every query.
2. **Snapshot Duplication**: Storing `order_items.unit_price` at the time of purchase (immutable historical record, not true redundant drift).
3. **Lookup Redundancy**: Storing `orders.customer_country` directly to accelerate geographically partitioned analytics.

---

## 3. PostgreSQL Materialized Views

A **Materialized View** executes a query once, writes the tabular result to disk as a physical relation, and allows indexes to be built on top of it.

```sql
-- Create Materialized View for customer lifetime value summary
CREATE MATERIALIZED VIEW mv_customer_spending_summary AS
SELECT
    c.id AS customer_id,
    c.email,
    COUNT(o.id) AS total_orders,
    COALESCE(SUM(o.total), 0) AS lifetime_value,
    MAX(o.placed_at) AS last_order_date
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id AND o.status = 'DELIVERED'
GROUP BY c.id, c.email;

-- Create unique index enabling concurrent zero-downtime refreshes
CREATE UNIQUE INDEX idx_mv_customer_spending_pk ON mv_customer_spending_summary (customer_id);

-- Refresh the materialized view in the background without locking readers
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_spending_summary;
```

---

## 4. Interview Questions

**Q: What are the trade-offs of `REFRESH MATERIALIZED VIEW CONCURRENTLY` in PostgreSQL?**
**Answer**: `REFRESH MATERIALIZED VIEW CONCURRENTLY` allows concurrent read queries to continue reading the old version of the view while the refresh is being computed. The trade-offs are:
1. It requires a `UNIQUE` index on one or more columns of the materialized view.
2. It takes longer and consumes more memory/temp disk space than a non-concurrent refresh because it generates a diff and applies row-by-row updates.
3. Data is eventual consistency — queries see the snapshot from the last refresh timestamp until the new refresh completes.
