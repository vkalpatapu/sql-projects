-- =============================================
-- NORTHWIND TRADING COMPANY
-- Business Analysis — SQL Project
-- Analyst: Venkat Kalpatapu
-- Date: June 2026
-- =============================================

-- =============================================
-- QUERY 1: Business Health Check
-- Question: What is the overall snapshot of
-- Northwind Trading Company performance?
-- Result: $1.35M revenue | 830 orders | 
--         89 customers | 77 products | $1,631 AOV
-- =============================================

SELECT 
    ROUND(SUM(od.quantity * od.unit_price)::NUMERIC, 2) 
        AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    COUNT(DISTINCT od.product_id) AS total_products,
    ROUND(SUM(od.quantity * od.unit_price)::NUMERIC 
        / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM order_details od
JOIN orders o ON od.order_id = o.order_id;


-- =============================================
-- QUERY 2: Top 10 Customers by Revenue
-- Question: Who are our most valuable customers?
-- Result: Top 3 = $346K = 25% of total revenue
-- =============================================
SELECT 
    c.customer_id,
    c.company_name,
    ROUND(SUM(od.quantity * od.unit_price)::NUMERIC, 2) AS total_revenue,
    RANK() OVER (
        ORDER BY SUM(od.quantity * od.unit_price) DESC
    ) AS revenue_rank
FROM order_details od
JOIN orders o ON od.order_id = o.order_id
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.company_name
ORDER BY total_revenue DESC
LIMIT 10;

-- =============================================
-- QUERY 3: Revenue by Country
-- Question: Which markets drive most revenue?
-- =============================================

SELECT 
    ship_country,
    ROUND(SUM(od.quantity * od.unit_price)::NUMERIC, 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND((SUM(od.quantity * od.unit_price) * 100.0 
        / SUM(SUM(od.quantity * od.unit_price)) OVER ()
        )::NUMERIC, 2) AS revenue_pct
FROM order_details od
JOIN orders o ON od.order_id = o.order_id
GROUP BY ship_country
ORDER BY total_revenue DESC;

-- =============================================
-- QUERY 4: Best Selling Products
-- Question: Which products make us most money?
-- Result: Côte de Blaye #1 at $149,984
-- =============================================
SELECT 
    p.product_name,
    ROUND(SUM(od.quantity * od.unit_price)::NUMERIC, 2) AS total_revenue,
    SUM(od.quantity) AS total_quantity_sold
FROM order_details od
JOIN products p ON od.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- =============================================
-- QUERY 5: Category Performance
-- Question: Which product categories drive 
-- most revenue for Northwind?
-- Result: Beverages #1 at $286K | 
--         Top 2 categories = 39.6% of revenue
-- =============================================
SELECT 
    c.category_name,
    ROUND(SUM(od.quantity * od.unit_price)::NUMERIC, 2) AS total_revenue,
    COUNT(DISTINCT od.product_id) AS total_products
FROM order_details od
JOIN products p ON od.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_revenue DESC;


-- =============================================
-- QUERY 6: Employee Performance
-- Question: Which employees generate most revenue?
-- Result: Margaret Peacock #1 at $250K
--         Top 3 employees = 49% of total revenue
--         Key person risk — concentration in 3 staff
-- =============================================
SELECT 
    e.first_name || ' ' || e.last_name AS employee_name,
    ROUND(SUM(od.quantity * od.unit_price)::NUMERIC, 2) 
        AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM order_details od
JOIN orders o ON od.order_id = o.order_id
JOIN employees e ON e.employee_id = o.employee_id
GROUP BY employee_name
ORDER BY total_revenue DESC;

-- =============================================
-- QUERY 7: Monthly Revenue Trend
-- Question: Is our business growing month 
-- over month? Show revenue trends over time.
-- Result: Business grew from $30K to $134K/month
--         1996→1997: +54% | 1997→1998: +100% YoY
--         May 1998 = incomplete data, not decline
-- =============================================
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', o.order_date) AS month,
        ROUND(SUM(od.quantity * od.unit_price)::NUMERIC, 2) 
            AS total_revenue
    FROM order_details od
    JOIN orders o ON od.order_id = o.order_id
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT 
    month,
    total_revenue,
    LAG(total_revenue, 1) OVER (ORDER BY month) AS prev_month,
    ROUND((total_revenue - LAG(total_revenue, 1) 
        OVER (ORDER BY month))::NUMERIC, 2) AS mom_change
FROM monthly_revenue
ORDER BY month;

-- =============================================
-- QUERY 8: High Value Orders
-- Question: What are our 20 biggest single orders?
-- Result: Order 10865 (QUICK-Stop) = $17,250 #1
--         QUICK-Stop appears 4x in top 20
--         Andrew Fuller manages most high value orders
-- =============================================
SELECT 
    od.order_id,
    c.company_name,
    e.first_name || ' ' || e.last_name AS employee_name,
    o.order_date,
    ROUND(SUM(od.quantity * od.unit_price)::NUMERIC, 2) 
        AS order_total
FROM order_details od
JOIN orders o ON od.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN employees e ON o.employee_id = e.employee_id
GROUP BY od.order_id, c.company_name, 
         employee_name, o.order_date
ORDER BY order_total DESC
LIMIT 20;