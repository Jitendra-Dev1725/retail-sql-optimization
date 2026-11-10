-- ============================================================
-- OPTIMIZATION STEPS (run after sample_data.sql)
-- Step 1: Indexing        Step 2: Partitioning
-- (Step 3: Query rewriting is in optimized_queries.sql)
-- ============================================================

-- ---------- STEP 1: INDEXES ----------

-- Q2: customer order history (equality on customer_id, sorted by date)
-- Composite index lets PostgreSQL find the rows AND return them already sorted.
CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date DESC);

-- Q4: inventory lookup by product
CREATE INDEX idx_inventory_product ON inventory (product_id);

-- Q7: low stock alert -> composite index (equality column first, range column second)
-- INCLUDE makes it a covering index, so no table visit is needed.
CREATE INDEX idx_inventory_store_stock
    ON inventory (store_id, stock_qty)
    INCLUDE (inventory_id, product_id, last_updated);

-- (Experiment) Q3: an index on order_items(order_id) was also tested. PostgreSQL's planner
-- ignored it (a parallel seq scan was cheaper because ~20% of the table matched), so it was
-- dropped again to avoid 27 MB of useless index + slower writes:
--   CREATE INDEX idx_order_items_order ON order_items (order_id) INCLUDE (product_id, quantity);

-- Q1 / Q3 / Q6: range filter on order_date (also helps Q5 after rewriting)
CREATE INDEX idx_orders_date ON orders (order_date) INCLUDE (store_id, status, total_amount, customer_id);

-- ---------- STEP 2: PARTITIONING (orders by order_date, yearly RANGE) ----------

CREATE TABLE orders_part (
    order_id     INT NOT NULL,
    customer_id  INT NOT NULL,
    store_id     INT NOT NULL,
    order_date   DATE NOT NULL,
    status       VARCHAR(15) NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    PRIMARY KEY (order_id, order_date)
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2023 PARTITION OF orders_part FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE orders_2024 PARTITION OF orders_part FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE orders_2025 PARTITION OF orders_part FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE orders_2026 PARTITION OF orders_part FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

INSERT INTO orders_part SELECT * FROM orders;

CREATE INDEX idx_orders_part_date ON orders_part (order_date) INCLUDE (store_id, status, total_amount, customer_id);

ANALYZE;

-- ---------- STEP 3: MATERIALIZED VIEW (pre-aggregation for Q3) ----------
-- Indexing + partitioning barely helped Q3 because the query must still read
-- hundreds of thousands of order_items rows. Pre-aggregating sales per day and
-- product removes that heavy join from the report query completely.

CREATE MATERIALIZED VIEW mv_daily_product_sales AS
SELECT o.order_date, oi.product_id, SUM(oi.quantity) AS units_sold
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
GROUP BY o.order_date, oi.product_id;

CREATE INDEX idx_mv_daily_date ON mv_daily_product_sales (order_date);

-- Refresh nightly (e.g. via cron / pg_cron):
--   REFRESH MATERIALIZED VIEW mv_daily_product_sales;

ANALYZE mv_daily_product_sales;
