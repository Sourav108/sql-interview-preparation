# Database Design Case 1: E-Commerce Order & Inventory Engine

## 1. Requirements
- **Functional**: Customers browse products, manage shopping carts, checkout orders with multiple items, process payments, and track inventory.
- **Data Integrity**: **Zero overselling** (inventory cannot drop below 0 under flash sale concurrency); historical product prices on past orders must remain completely immutable.
- **Scale**: 10,000 QPS reads on catalog, 2,000 QPS order checkouts.

---

## 2. Schema DDL & Integrity Constraints

```sql
CREATE TYPE order_status AS ENUM ('PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED');
CREATE TYPE payment_status AS ENUM ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED');

CREATE TABLE customers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku VARCHAR(64) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    current_price NUMERIC(10,2) NOT NULL CHECK (current_price >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE inventory (
    product_id BIGINT PRIMARY KEY REFERENCES products (id) ON DELETE CASCADE,
    stock_qty INT NOT NULL CHECK (stock_qty >= 0), -- Enforces zero overselling at DB storage level!
    reserved_qty INT NOT NULL DEFAULT 0 CHECK (reserved_qty >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers (id),
    status order_status NOT NULL DEFAULT 'PENDING',
    subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
    shipping_cost NUMERIC(8,2) NOT NULL DEFAULT 0.00,
    total NUMERIC(12,2) NOT NULL CHECK (total >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE order_items (
    order_id BIGINT NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products (id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0), -- Immutable snapshot of price!
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders (id),
    idempotency_key VARCHAR(64) NOT NULL UNIQUE,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    status payment_status NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 3. Atomic Checkout Transaction with Flash-Sale Concurrency

```sql
BEGIN;

-- 1. Atomically deduct inventory with DB-level guard (Prevents Race Conditions)
UPDATE inventory
SET stock_qty = stock_qty - 1,
    reserved_qty = reserved_qty + 1
WHERE product_id = 42
  AND stock_qty >= 1;

-- If rows_affected == 0: Stock is exhausted! ROLLBACK and return "Out of Stock" HTTP 409.

-- 2. Create Order & Line Item
INSERT INTO orders (customer_id, subtotal, shipping_cost, total)
VALUES (101, 8500.00, 0.00, 8500.00) RETURNING id; -- returns order_id = 5001

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (5001, 42, 1, 8500.00);

-- 3. Create Pending Payment with Idempotency Key
INSERT INTO payments (order_id, idempotency_key, amount, status)
VALUES (5001, 'IDEM-ORDER-5001-v1', 8500.00, 'PENDING');

COMMIT;
```

---

## 4. Key Architectural Trade-offs
- **Separate `inventory` table**: Isolates high-frequency row write locks on `stock_qty` from the read-heavy `products` table.
- **Snapshot `order_items.unit_price`**: Stores the price at the second of checkout, decoupling historical order accounting from future product price updates.
