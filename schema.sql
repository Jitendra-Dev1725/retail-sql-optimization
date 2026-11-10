-- ============================================================
-- Retail database schema (PostgreSQL)
-- Week 3: SQL Query Optimization and Performance Tuning
-- ============================================================
-- NOTE: This is the BASELINE schema. Only primary keys exist.
-- No secondary indexes and no partitioning yet, so that we can
-- measure "before" performance honestly.
-- ============================================================

DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS stores CASCADE;

CREATE TABLE stores (
    store_id    INT PRIMARY KEY,
    store_name  VARCHAR(80)  NOT NULL,
    city        VARCHAR(50)  NOT NULL,
    region      VARCHAR(20)  NOT NULL
);

CREATE TABLE customers (
    customer_id  INT PRIMARY KEY,
    full_name    VARCHAR(80)  NOT NULL,
    email        VARCHAR(100) NOT NULL,
    city         VARCHAR(50)  NOT NULL,
    signup_date  DATE         NOT NULL
);

CREATE TABLE products (
    product_id    INT PRIMARY KEY,
    product_name  VARCHAR(100) NOT NULL,
    category      VARCHAR(30)  NOT NULL,
    brand         VARCHAR(30)  NOT NULL,
    unit_price    NUMERIC(10,2) NOT NULL
);

CREATE TABLE inventory (
    inventory_id  INT PRIMARY KEY,
    store_id      INT NOT NULL REFERENCES stores(store_id),
    product_id    INT NOT NULL REFERENCES products(product_id),
    stock_qty     INT NOT NULL,
    last_updated  DATE NOT NULL
);

CREATE TABLE orders (
    order_id     INT PRIMARY KEY,
    customer_id  INT  NOT NULL REFERENCES customers(customer_id),
    store_id     INT  NOT NULL REFERENCES stores(store_id),
    order_date   DATE NOT NULL,
    status       VARCHAR(15) NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL
);

CREATE TABLE order_items (
    item_id     INT PRIMARY KEY,
    order_id    INT NOT NULL REFERENCES orders(order_id),
    product_id  INT NOT NULL REFERENCES products(product_id),
    quantity    INT NOT NULL,
    unit_price  NUMERIC(10,2) NOT NULL
);
