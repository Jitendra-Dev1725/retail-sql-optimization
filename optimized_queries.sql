-- ============================================================
-- OPTIMIZED queries (after indexing + rewriting + partitioning)
-- Same business questions as baseline_queries.sql
-- ============================================================

-- Q1: Sales report - uses partitioned table + date index (partition pruning)
SELECT s.store_name, COUNT(*) AS orders, SUM(o.total_amount) AS revenue
FROM orders_part o
JOIN stores s ON s.store_id = o.store_id
WHERE o.order_date >= DATE '2026-03-01'
  AND o.order_date <  DATE '2026-04-01'
  AND o.status = 'COMPLETED'
GROUP BY s.store_name
ORDER BY revenue DESC;

-- Q2: Customer history - SELECT * replaced by needed columns, composite index used
SELECT order_id, order_date, status, total_amount
FROM orders
WHERE customer_id = 12345
ORDER BY order_date DESC;

-- Q3: Top 10 products - reads the pre-aggregated materialized view instead of joining 900k rows
SELECT p.product_name, SUM(m.units_sold) AS units_sold
FROM mv_daily_product_sales m
JOIN products p ON p.product_id = m.product_id
WHERE m.order_date >= DATE '2026-01-01'
  AND m.order_date <  DATE '2026-04-01'
GROUP BY p.product_name
ORDER BY units_sold DESC
LIMIT 10;

-- Q4: Inventory lookup - same query, now uses idx_inventory_product
SELECT st.store_name, i.stock_qty, i.last_updated
FROM inventory i
JOIN stores st ON st.store_id = i.store_id
WHERE i.product_id = 777;

-- Q5: Monthly revenue - function on column replaced by a sargable date range
SELECT EXTRACT(MONTH FROM order_date) AS month, SUM(total_amount) AS revenue
FROM orders_part
WHERE order_date >= DATE '2025-01-01'
  AND order_date <  DATE '2026-01-01'
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY month;

-- Q6: Re-engagement list - NOT IN rewritten as NOT EXISTS (anti-join)
SELECT c.customer_id, c.full_name, c.email
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
      AND o.order_date >= DATE '2026-01-01'
);

-- Q7: Low-stock alert - SELECT * replaced by needed columns -> covering index (index-only scan)
SELECT inventory_id, product_id, stock_qty, last_updated
FROM inventory
WHERE store_id = 5
  AND stock_qty < 20;
