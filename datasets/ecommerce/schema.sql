-- ============================================================
-- E-Commerce Dataset: Schema DDL
-- PostgreSQL 18.6 | sql-interview-preparation
-- ============================================================

-- Drop tables in dependency order for clean reloads
DROP TABLE IF EXISTS payments    CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders      CASCADE;
DROP TABLE IF EXISTS inventory   CASCADE;
DROP TABLE IF EXISTS products    CASCADE;
DROP TABLE IF EXISTS customers   CASCADE;

-- Drop enum types
DROP TYPE IF EXISTS payment_status CASCADE;
DROP TYPE IF EXISTS payment_method CASCADE;
DROP TYPE IF EXISTS order_status   CASCADE;
DROP TYPE IF EXISTS product_status CASCADE;

-- ────────────────────────────────────────────────────────────
-- ENUM TYPES
-- ────────────────────────────────────────────────────────────

-- [PostgreSQL Specific]: Native ENUM types
CREATE TYPE product_status AS ENUM ('ACTIVE', 'DISCONTINUED', 'OUT_OF_STOCK');
CREATE TYPE order_status   AS ENUM ('PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED');
CREATE TYPE payment_status AS ENUM ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED');
CREATE TYPE payment_method AS ENUM ('CREDIT_CARD', 'DEBIT_CARD', 'UPI', 'NET_BANKING', 'WALLET');

-- ────────────────────────────────────────────────────────────
-- CUSTOMERS
-- ────────────────────────────────────────────────────────────
CREATE TABLE customers (
    id             BIGINT        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email          VARCHAR(255)  NOT NULL,
    first_name     VARCHAR(100)  NOT NULL,
    last_name      VARCHAR(100)  NOT NULL,
    phone          VARCHAR(20),
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_customers_email UNIQUE (email)
);

COMMENT ON TABLE  customers IS 'Registered platform customers.';
COMMENT ON COLUMN customers.email IS 'Business unique key — enforced with UNIQUE constraint. Not used as FK target.';

-- ────────────────────────────────────────────────────────────
-- PRODUCTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE products (
    id             BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku            VARCHAR(50)     NOT NULL,
    name           VARCHAR(255)    NOT NULL,
    description    TEXT,
    category       VARCHAR(100),
    unit_price     NUMERIC(10, 2)  NOT NULL CHECK (unit_price >= 0),
    status         product_status  NOT NULL DEFAULT 'ACTIVE',
    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_products_sku UNIQUE (sku)
);

COMMENT ON COLUMN products.unit_price IS 'Current list price. Historical price is stored in order_items.unit_price.';

-- ────────────────────────────────────────────────────────────
-- INVENTORY (1:1 with products)
-- ────────────────────────────────────────────────────────────
CREATE TABLE inventory (
    product_id         BIGINT      PRIMARY KEY REFERENCES products (id) ON DELETE CASCADE,
    quantity_on_hand   INTEGER     NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    reorder_level      INTEGER     NOT NULL DEFAULT 10 CHECK (reorder_level >= 0),
    last_restocked_at  TIMESTAMPTZ,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ────────────────────────────────────────────────────────────
-- ORDERS
-- ────────────────────────────────────────────────────────────
CREATE TABLE orders (
    id               BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id      BIGINT          NOT NULL,
    status           order_status    NOT NULL DEFAULT 'PENDING',
    shipping_address TEXT            NOT NULL,
    subtotal         NUMERIC(12, 2)  NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    shipping_cost    NUMERIC(8, 2)   NOT NULL DEFAULT 0 CHECK (shipping_cost >= 0),
    total            NUMERIC(12, 2)  NOT NULL DEFAULT 0 CHECK (total >= 0),
    placed_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT
);

-- Performance indexes
CREATE INDEX idx_orders_customer_id ON orders (customer_id);
CREATE INDEX idx_orders_status      ON orders (status);
CREATE INDEX idx_orders_placed_at   ON orders (placed_at DESC);
CREATE INDEX idx_orders_customer_placed ON orders (customer_id, placed_at DESC);

-- ────────────────────────────────────────────────────────────
-- ORDER ITEMS (M:N junction: orders ↔ products)
-- ────────────────────────────────────────────────────────────
CREATE TABLE order_items (
    order_id     BIGINT          NOT NULL,
    product_id   BIGINT          NOT NULL,
    quantity     INTEGER         NOT NULL CHECK (quantity > 0),
    unit_price   NUMERIC(10, 2)  NOT NULL CHECK (unit_price >= 0),

    PRIMARY KEY (order_id, product_id),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)   REFERENCES orders   (id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
);

CREATE INDEX idx_order_items_product_id ON order_items (product_id);

-- ────────────────────────────────────────────────────────────
-- PAYMENTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE payments (
    id           BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id     BIGINT          NOT NULL,
    amount       NUMERIC(12, 2)  NOT NULL CHECK (amount > 0),
    method       payment_method  NOT NULL,
    status       payment_status  NOT NULL DEFAULT 'PENDING',
    gateway_ref  VARCHAR(100),
    paid_at      TIMESTAMPTZ,
    created_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE RESTRICT
);

CREATE INDEX idx_payments_order_id ON payments (order_id);
CREATE INDEX idx_payments_status   ON payments (status);
CREATE INDEX idx_payments_paid_at  ON payments (paid_at DESC) WHERE paid_at IS NOT NULL;
