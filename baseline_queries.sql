-- ============================================================
-- BASELINE queries (before optimization) - typical retail operations
-- Each query starts with a "-- Qn:" marker line used by benchmark.py
-- ============================================================

-- Q1: Sales report - revenue per store for one month
SELECT s.store_name, COUNT(*) AS orders, SUM(o.total_amount) AS revenue
FROM orders o
JOIN stores s ON s.store_id = o.store_id
WHERE o.order_date >= DATE '2026-03-01'
  AND o.order_date <  DATE '2026-04-01'
  AND o.status = 'COMPLETED'
GROUP BY s.store_name
ORDER BY revenue DESC;

-- Q2: Customer order history lookup (customer service screen)
SELECT *
FROM orders
WHERE customer_id = 12345
ORDER BY order_date DESC;

-- Q3: Top 10 best-selling products in a quarter
SELECT p.product_name, SUM(oi.quantity) AS units_sold
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_date >= DATE '2026-01-01'
  AND o.order_date <  DATE '2026-04-01'
GROUP BY p.product_name
ORDER BY units_sold DESC
LIMIT 10;

-- Q4: Inventory lookup - stock of one product across all stores
SELECT st.store_name, i.stock_qty, i.last_updated
FROM inventory i
JOIN stores st ON st.store_id = i.store_id
WHERE i.product_id = 777;

-- Q5: Monthly revenue for a year (function applied on the date column)
SELECT EXTRACT(MONTH FROM order_date) AS month, SUM(total_amount) AS revenue
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2025
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY month;

-- Q6: Customers who did NOT order in 2026 (NOT IN subquery) - re-engagement campaign
SELECT c.customer_id, c.full_name, c.email
FROM customers c
WHERE c.customer_id NOT IN (
    SELECT o.customer_id
    FROM orders o
    WHERE o.order_date >= DATE '2026-01-01'
);

-- Q7: Low-stock alert for one store
SELECT *
FROM inventory
WHERE store_id = 5
  AND stock_qty < 20;
