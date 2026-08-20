-- =============================================
-- SUPPLY CHAIN ANALYTICS PROJECT
-- Analyst: Venkat Kalpatapu
-- Dataset: DataCo Supply Chain (180,519 rows)
-- Tools: Excel Power Query → PostgreSQL → Power BI
-- =============================================

-- =============================================
-- PHASE 1: ETL + DATA CLEANING (Power Query)
-- =============================================
-- STEP 1: Loaded CSV via Power Query
-- STEP 2: Fixed Data Types
-- STEP 3: Removed Unnecessary Columns
-- STEP 4: Removed Blank Rows
-- STEP 5: Added Delivery_Performance column
-- STEP 6: Exported clean CSV → 180,519 rows

-- =============================================
-- PHASE 2: DATABASE SETUP (PostgreSQL)
-- =============================================-- =============================================
-- DATABASE SETUP
-- =============================================

CREATE TABLE supply_chain (
    type VARCHAR(20),
    days_shipping_real INTEGER,
    days_shipping_scheduled INTEGER,
    benefit_per_order NUMERIC(10,2),
    sales_per_customer NUMERIC(10,2),
    delivery_status VARCHAR(50),
    late_delivery_risk INTEGER,
    category_id INTEGER,
    category_name VARCHAR(100),
    customer_city VARCHAR(100),
    customer_country VARCHAR(100),
    customer_fname VARCHAR(50),
    customer_id INTEGER,
    customer_lname VARCHAR(50),
    customer_segment VARCHAR(50),
    customer_state VARCHAR(100),
    department_name VARCHAR(100),
    latitude NUMERIC(10,6),
    longitude NUMERIC(10,6),
    market VARCHAR(50),
    order_city VARCHAR(100),
    order_country VARCHAR(100),
    order_customer_id INTEGER,
    order_date DATE,
    order_id INTEGER,
    order_item_cardprod_id INTEGER,
    order_item_discount NUMERIC(10,2),
    order_item_discount_rate NUMERIC(5,4),
    order_item_id INTEGER,
    order_item_product_price NUMERIC(10,2),
    order_item_profit_ratio NUMERIC(10,4),
    order_item_quantity INTEGER,
    sales NUMERIC(10,2),
    order_item_total NUMERIC(10,2),
    order_profit_per_order NUMERIC(10,2),
    order_region VARCHAR(100),
    order_state VARCHAR(100),
    order_status VARCHAR(50),
    product_card_id INTEGER,
    product_category_id INTEGER,
    product_name VARCHAR(200),
    product_price NUMERIC(10,2),
    product_status INTEGER,
    shipping_date DATE,
    shipping_mode VARCHAR(50),
    delivery_performance VARCHAR(20)
);

COPY supply_chain
FROM 'C:/supply_chain_clean.csv'
DELIMITER ','
CSV HEADER
ENCODING 'LATIN1';

-- =============================================
-- KPI 1: Overall Business Health Check
-- Question: What is the overall supply chain
-- performance snapshot?
-- Result: 180,519 orders | $36.7M revenue
--         54.83% late delivery rate!
-- =============================================
SELECT 
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(benefit_per_order)::NUMERIC, 2) AS total_profit,
    ROUND(AVG(order_item_profit_ratio)::NUMERIC, 4) AS avg_profit_margin,
    ROUND(SUM(late_delivery_risk)::NUMERIC / COUNT(*) * 100, 2) 
        AS late_delivery_pct
FROM supply_chain;

-- =============================================
-- KPI 2: On-Time Delivery by Shipping Mode
-- Question: Which shipping mode has worst
-- late delivery rate?
-- Result: First Class worst at 95.32%!
--         Standard Class best at 38.07%
-- =============================================
SELECT 
    shipping_mode,
    COUNT(*) AS total_shipments,
    SUM(late_delivery_risk) AS late_count,
    ROUND(SUM(late_delivery_risk)::NUMERIC / COUNT(*) * 100, 2) 
        AS late_delivery_pct,
    ROUND(AVG(days_shipping_real)::NUMERIC, 2) AS actual_days,
    ROUND(AVG(days_shipping_scheduled)::NUMERIC, 2) AS promised_days
FROM supply_chain
GROUP BY shipping_mode
ORDER BY late_delivery_pct DESC;

-- =============================================
-- KPI 3: Category Performance with RANK
-- Question: Which categories are most profitable?
-- New skills: CTE + RANK() + revenue share %
-- Result: Fishing #1 at $756K | 18.84% share
--         Strength Training 0.61% margin!
-- =============================================
WITH category_stats AS (
    SELECT
        category_name,
        ROUND(SUM(sales)::NUMERIC, 2) AS total_revenue,
        ROUND(SUM(benefit_per_order)::NUMERIC, 2) AS total_profit,
        ROUND(SUM(benefit_per_order)::NUMERIC / 
            SUM(sales) * 100, 2) AS profit_margin_pct,
        COUNT(DISTINCT order_id) AS total_orders
    FROM supply_chain
    GROUP BY category_name
)
SELECT
    category_name,
    total_revenue,
    total_profit,
    profit_margin_pct,
    total_orders,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    ROUND(total_revenue * 100.0 / 
        SUM(total_revenue) OVER (), 2) AS revenue_share_pct
FROM category_stats
ORDER BY profit_rank;

-- =============================================
-- KPI 4: Market Growth Trends with LAG
-- Question: Which markets are growing vs declining?
-- New skills: CTE + LAG() + YoY growth %
-- Result: USCA collapsed -99.54% in 2017!
--         Europe recovered +582% in 2017
-- =============================================
WITH market_yearly AS (
    SELECT
        market,
        EXTRACT(YEAR FROM order_date) AS year,
        ROUND(SUM(sales)::NUMERIC, 2) AS total_revenue,
        COUNT(DISTINCT order_id) AS total_orders
    FROM supply_chain
    GROUP BY market, EXTRACT(YEAR FROM order_date)
)
SELECT
    market,
    year,
    total_revenue,
    total_orders,
    LAG(total_revenue) OVER (
        PARTITION BY market ORDER BY year
    ) AS prev_year_revenue,
    ROUND((total_revenue - LAG(total_revenue) OVER (
        PARTITION BY market ORDER BY year
    ))::NUMERIC / LAG(total_revenue) OVER (
        PARTITION BY market ORDER BY year
    ) * 100, 2) AS growth_pct,
    CASE WHEN LAG(total_revenue) OVER (
        PARTITION BY market ORDER BY year) IS NULL
         THEN '🆕 First Year'
         WHEN total_revenue > LAG(total_revenue) OVER (
        PARTITION BY market ORDER BY year)
         THEN '📈 Growing'
         ELSE '📉 Declining'
    END AS trend
FROM market_yearly
ORDER BY market, year;

-- =============================================
-- KPI 5: Customer Segmentation with NTILE
-- Question: Divide customers into spending
-- quartiles — who are our top tier customers?
-- New skills: CTE + NTILE(4) window function
-- Result: Mary Smith dominates top tier
--         Possible data quality issue flagged
-- =============================================
WITH customer_spending AS (
    SELECT
        customer_fname || ' ' || customer_lname AS customer_name,
        market,
        customer_segment,
        ROUND(SUM(sales)::NUMERIC, 2) AS total_spent,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(AVG(order_item_discount_rate)::NUMERIC * 100, 2) 
            AS avg_discount_pct
    FROM supply_chain
    GROUP BY market, customer_name, customer_segment
)
SELECT
    customer_name,
    customer_segment,
    market,
    total_spent,
    total_orders,
    avg_discount_pct,
    NTILE(4) OVER (ORDER BY total_spent DESC) AS spending_quartile,
    CASE WHEN NTILE(4) OVER (ORDER BY total_spent DESC) = 1
         THEN '⭐ Top Tier'
         WHEN NTILE(4) OVER (ORDER BY total_spent DESC) = 2
         THEN '🔵 High Value'
         WHEN NTILE(4) OVER (ORDER BY total_spent DESC) = 3
         THEN '🟡 Mid Value'
         ELSE '⚠️ At Risk'
    END AS customer_tier
FROM customer_spending
ORDER BY total_spent DESC
LIMIT 20;