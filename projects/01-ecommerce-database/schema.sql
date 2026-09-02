DROP TABLE IF EXISTS proj_payments CASCADE;
DROP TABLE IF EXISTS proj_order_items CASCADE;
DROP TABLE IF EXISTS proj_orders CASCADE;
DROP TABLE IF EXISTS proj_inventory CASCADE;
DROP TABLE IF EXISTS proj_products CASCADE;
DROP TABLE IF EXISTS proj_customers CASCADE;

CREATE TABLE proj_customers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE proj_products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku VARCHAR(64) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    current_price NUMERIC(10,2) NOT NULL CHECK (current_price >= 0)
);

CREATE TABLE proj_inventory (
    product_id BIGINT PRIMARY KEY REFERENCES proj_products(id) ON DELETE CASCADE,
    stock_qty INT NOT NULL CHECK (stock_qty >= 0),
    reserved_qty INT NOT NULL DEFAULT 0 CHECK (reserved_qty >= 0)
);

CREATE TABLE proj_orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES proj_customers(id),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    total NUMERIC(12,2) NOT NULL CHECK (total >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE proj_order_items (
    order_id BIGINT NOT NULL REFERENCES proj_orders(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES proj_products(id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE proj_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES proj_orders(id),
    idempotency_key VARCHAR(64) NOT NULL UNIQUE,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_proj_orders_customer ON proj_orders(customer_id, created_at DESC);
CREATE INDEX idx_proj_items_product ON proj_order_items(product_id);
