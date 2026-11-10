-- ============================================================
-- Sample data generation (PostgreSQL) using generate_series
-- Volumes: 20 stores, 50,000 customers, 5,000 products,
--          300,000 orders, ~900,000 order_items, 100,000 inventory rows
-- ============================================================

-- Make results reproducible
SELECT setseed(0.42);

INSERT INTO stores
SELECT s,
       'Store ' || s,
       (ARRAY['Mumbai','Delhi','Bengaluru','Chennai','Pune','Hyderabad','Kolkata','Jaipur'])[1 + (s % 8)],
       (ARRAY['West','North','South','East'])[1 + (s % 4)]
FROM generate_series(1, 20) s;

INSERT INTO customers
SELECT c,
       'Customer ' || c,
       'customer' || c || '@example.com',
       (ARRAY['Mumbai','Delhi','Bengaluru','Chennai','Pune','Hyderabad','Kolkata','Jaipur'])[1 + (c % 8)],
       DATE '2020-01-01' + (random() * 1800)::INT
FROM generate_series(1, 50000) c;

INSERT INTO products
SELECT p,
       'Product ' || p,
       (ARRAY['Grocery','Electronics','Apparel','Home','Beauty','Sports','Toys','Books'])[1 + (p % 8)],
       'Brand' || (1 + (p % 40)),
       round((50 + random() * 4950)::numeric, 2)
FROM generate_series(1, 5000) p;

INSERT INTO inventory
SELECT i,
       1 + (i % 20),
       1 + (i % 5000),
       (random() * 500)::INT,
       DATE '2026-01-01' + (random() * 300)::INT
FROM generate_series(1, 100000) i;

-- 300,000 orders spread across 2023-01-01 .. 2026-10-31 (~1400 days)
INSERT INTO orders
SELECT o,
       1 + (random() * 49999)::INT,
       1 + (random() * 19)::INT,
       DATE '2023-01-01' + (random() * 1399)::INT,
       (ARRAY['COMPLETED','COMPLETED','COMPLETED','COMPLETED','SHIPPED','PENDING','CANCELLED'])[1 + (random() * 6)::INT],
       0
FROM generate_series(1, 300000) o;

-- 3 line items per order on average
INSERT INTO order_items
SELECT row_number() OVER (),
       o.order_id,
       1 + (random() * 4999)::INT,
       1 + (random() * 4)::INT,
       round((50 + random() * 4950)::numeric, 2)
FROM orders o
CROSS JOIN generate_series(1, 3) g;

-- Fill order totals from items
UPDATE orders o
SET total_amount = t.total
FROM (SELECT order_id, SUM(quantity * unit_price) AS total
      FROM order_items GROUP BY order_id) t
WHERE o.order_id = t.order_id;

ANALYZE;
