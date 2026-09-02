# 02. Full E-Commerce Schema: Business Requirement to DDL

## 1. Business Requirement

> "We operate an e-commerce platform. Customers register with an email address and name. Customers can place multiple orders. Each order has a shipping address and a status that progresses through PENDING → CONFIRMED → SHIPPED → DELIVERED. Orders contain line items — each line item references a product at the price it was sold (not the current price). Products have a name, description, SKU, and current price. We need to track inventory quantities. Payments are recorded separately per order."

---

## 2. Entity Extraction

| Noun (Entity) | Becomes Table | Key Observations |
| :--- | :--- | :--- |
| Customer | `customers` | Has email (natural unique key), name, and registration timestamp |
| Order | `orders` | Belongs to a customer; has shipping address, status, and timestamps |
| OrderItem (line item) | `order_items` | Junction between Order and Product; stores quantity + price *at time of purchase* |
| Product | `products` | Has SKU (natural key), name, description, price |
| Inventory | `inventory` | 1:1 with Product; stock quantity managed separately |
| Payment | `payments` | Belongs to an Order; has method, amount, status |

---

## 3. Relationship Map

```
customers (1) ──────< (N) orders
orders    (1) ──────< (N) order_items >──────── (N) products (1)
products  (1) ──────── (1) inventory
orders    (1) ──────< (N) payments
```

---

## 4. Full Schema DDL

```sql
-- [Standard SQL with PostgreSQL extensions noted]

-- ──────────────────────────────────────────────────────────────
-- CUSTOMERS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE customers (
    id             BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email          VARCHAR(255) NOT NULL,
    first_name     VARCHAR(100) NOT NULL,
    last_name      VARCHAR(100) NOT NULL,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_customers_email UNIQUE (email)
);

-- ──────────────────────────────────────────────────────────────
-- PRODUCTS
-- ──────────────────────────────────────────────────────────────
CREATE TYPE product_status AS ENUM ('ACTIVE', 'DISCONTINUED', 'OUT_OF_STOCK');
-- [PostgreSQL Specific]: ENUM type; SQL Standard uses CHECK constraints

CREATE TABLE products (
    id             BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku            VARCHAR(50)     NOT NULL,
    name           VARCHAR(255)    NOT NULL,
    description    TEXT,
    unit_price     NUMERIC(10, 2)  NOT NULL CHECK (unit_price >= 0),
    status         product_status  NOT NULL DEFAULT 'ACTIVE',
    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_products_sku UNIQUE (sku)
);

-- ──────────────────────────────────────────────────────────────
-- INVENTORY (1:1 with products)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE inventory (
    product_id     BIGINT   PRIMARY KEY REFERENCES products (id) ON DELETE CASCADE,
    quantity_on_hand INTEGER NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    reorder_level  INTEGER  NOT NULL DEFAULT 10,
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────
-- ORDERS
-- ──────────────────────────────────────────────────────────────
CREATE TYPE order_status AS ENUM ('PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED');

CREATE TABLE orders (
    id                  BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id         BIGINT         NOT NULL,
    status              order_status   NOT NULL DEFAULT 'PENDING',
    shipping_address    TEXT           NOT NULL,
    subtotal            NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    shipping_cost       NUMERIC(8, 2)  NOT NULL DEFAULT 0 CHECK (shipping_cost >= 0),
    total               NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    placed_at           TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT
);

CREATE INDEX idx_orders_customer_id ON orders (customer_id);
CREATE INDEX idx_orders_status      ON orders (status);
CREATE INDEX idx_orders_placed_at   ON orders (placed_at DESC);

-- ──────────────────────────────────────────────────────────────
-- ORDER ITEMS (junction: orders ↔ products)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE order_items (
    order_id    BIGINT         NOT NULL,
    product_id  BIGINT         NOT NULL,
    quantity    INTEGER        NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),  -- price at time of sale

    PRIMARY KEY (order_id, product_id),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
);

CREATE INDEX idx_order_items_product_id ON order_items (product_id);

-- ──────────────────────────────────────────────────────────────
-- PAYMENTS
-- ──────────────────────────────────────────────────────────────
CREATE TYPE payment_status  AS ENUM ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED');
CREATE TYPE payment_method  AS ENUM ('CREDIT_CARD', 'DEBIT_CARD', 'UPI', 'NET_BANKING', 'WALLET');

CREATE TABLE payments (
    id             BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id       BIGINT          NOT NULL,
    amount         NUMERIC(12, 2)  NOT NULL CHECK (amount > 0),
    method         payment_method  NOT NULL,
    status         payment_status  NOT NULL DEFAULT 'PENDING',
    gateway_ref    VARCHAR(100),
    paid_at        TIMESTAMPTZ,
    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE RESTRICT
);

CREATE INDEX idx_payments_order_id ON payments (order_id);
CREATE INDEX idx_payments_status   ON payments (status);
```

---

## 5. Sample Data

```sql
INSERT INTO customers (email, first_name, last_name) VALUES
    ('alice@example.com', 'Alice',   'Chen'),
    ('bob@example.com',   'Bob',     'Kapoor'),
    ('carol@example.com', 'Carol',   'Lima');

INSERT INTO products (sku, name, unit_price) VALUES
    ('SKU-001', 'Mechanical Keyboard',  8500.00),
    ('SKU-002', 'Wireless Mouse',       2500.00),
    ('SKU-003', 'USB-C Hub 7-Port',     3200.00),
    ('SKU-004', 'Monitor Stand',        4100.00);

INSERT INTO inventory (product_id, quantity_on_hand) VALUES
    (1, 50), (2, 200), (3, 80), (4, 30);

INSERT INTO orders (customer_id, status, shipping_address, subtotal, shipping_cost, total)
VALUES
    (1, 'DELIVERED', '42 Maple St, Mumbai', 11000.00, 0.00, 11000.00),
    (1, 'SHIPPED',   '42 Maple St, Mumbai', 3200.00,  99.00, 3299.00),
    (2, 'PENDING',   '7 Park Ave, Delhi',   8500.00,  0.00,  8500.00);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 8500.00),
    (1, 2, 1, 2500.00),
    (2, 3, 1, 3200.00),
    (3, 1, 1, 8500.00);

INSERT INTO payments (order_id, amount, method, status, paid_at) VALUES
    (1, 11000.00, 'CREDIT_CARD', 'COMPLETED', NOW() - INTERVAL '5 days'),
    (2, 3299.00,  'UPI',         'COMPLETED', NOW() - INTERVAL '2 days'),
    (3, 8500.00,  'NET_BANKING', 'PENDING',   NULL);
```

---

## 6. Validation Queries

```sql
-- 1. Total revenue per customer
SELECT
    c.first_name || ' ' || c.last_name AS customer,
    COUNT(DISTINCT o.id)               AS total_orders,
    SUM(o.total)                       AS lifetime_value
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE o.status != 'CANCELLED'
GROUP BY c.id, c.first_name, c.last_name
ORDER BY lifetime_value DESC;

-- 2. Products sold with quantities (uses order_items correctly)
SELECT
    p.name,
    SUM(oi.quantity)                  AS total_units_sold,
    SUM(oi.quantity * oi.unit_price)  AS total_revenue
FROM order_items oi
JOIN products p ON p.id = oi.product_id
JOIN orders   o ON o.id = oi.order_id
WHERE o.status IN ('DELIVERED', 'SHIPPED')
GROUP BY p.id, p.name
ORDER BY total_revenue DESC;

-- 3. Orders with no payment completed (outstanding balances)
SELECT o.id, o.total, o.status, o.placed_at
FROM orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM payments p
    WHERE p.order_id = o.id AND p.status = 'COMPLETED'
);
```

---

## 7. Design Decisions & Trade-offs

| Decision | Rationale | Alternative Considered |
| :--- | :--- | :--- |
| `unit_price` stored in `order_items` | Price at time of sale must be immutable; current `products.unit_price` can change | Storing only `product_id` would corrupt historical revenue calculations |
| Separate `inventory` table (1:1 with products) | Inventory management writes (stock adjustments) are high-frequency; separating avoids locking the `products` row on every stock update | Single `products` table with `stock_qty` column (simpler but creates hot-row contention) |
| `subtotal`, `shipping_cost`, `total` stored on `orders` | Avoids expensive recalculation on every read; denormalized aggregate | Recomputing `SUM(order_items.quantity * unit_price)` on every query is O(N) in items |
| ENUM types for `status`, `method` | Type safety + compact storage; enforces valid values at DB layer | `VARCHAR` + `CHECK` constraint (less readable, same enforcement) |

---

## 8. Interview Questions

**Q1: Why do you store `unit_price` in `order_items` and not just in `products`?**
Because the price at the time of purchase must be immutable. The `products.unit_price` column reflects the *current* price, which changes over time via promotions, inflation, or repricing. If historical line items referenced only `product_id`, recomputing past order totals after a price change would produce wrong results. Capturing `unit_price` at the point of insertion preserves the financial audit trail.

**Q2: Walk me through converting a many-to-many relationship into a schema.**
A many-to-many relationship (Orders ↔ Products) cannot be represented with a simple FK. You create a third **junction table** (`order_items`) that contains FK columns referencing each parent table. The junction's PK is the composite of both FKs, preventing duplicate associations. If the relationship itself carries attributes (quantity, price), those go directly in the junction table, making it an **associative entity** rather than a pure pivot table.

**Q3: How would you change this schema to support product variants (color, size)?**
Add a `product_variants` table: `(id, product_id, size, color, sku, price, stock_qty)`. `order_items` then references `variant_id` instead of `product_id`. This shifts from a 1-level to a 2-level product hierarchy. The `products` table becomes a product **family/template**, and `product_variants` holds each sellable SKU.
