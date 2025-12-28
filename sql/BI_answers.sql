/* 
   PURPOSE: Business Intelligence Queries for Sales Analytics
   This script transforms raw transactional data into executive KPIs,
   answering client BI questions on revenue, products, cities, and trends.
   Designed for clear insights, stakeholder reporting, and Power BI dashboards.*/
   
   
   USE sales_db;

-- 1️Total Revenue & Units Sold (Executive KPI)

SELECT
    SUM(sales)    AS total_revenue,
    SUM(quantity) AS total_units_sold
FROM stage_fact_sales
WHERE is_valid_record = 1;


-- 2 Monthly Revenue Trend (Growth & Seasonality)
SELECT
    d.order_year,
    d.order_month,
    SUM(s.sales) AS monthly_revenue
FROM stage_fact_sales s
JOIN dim_date d
    ON s.date_id = d.date_id
WHERE s.is_valid_record = 1
GROUP BY d.order_year, d.order_month
ORDER BY d.order_year, d.order_month;

-- 3. Top 10 Products by Revenue
SELECT
    p.product_name,
    SUM(s.sales) AS revenue
FROM stage_fact_sales s
JOIN dim_product p ON s.product_id = p.product_id
WHERE s.is_valid_record = 1
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 10;

-- 4. Revenue by City
SELECT
    c.city_name,
    SUM(s.sales) AS revenue
FROM stage_fact_sales s
JOIN dim_city c ON s.city_id = c.city_id
WHERE s.is_valid_record = 1
GROUP BY c.city_name
ORDER BY revenue DESC;

-- 5. Revenue & Units by Time of Day
SELECT
    d.time_of_day,
    SUM(s.sales) AS revenue,
    SUM(s.quantity) AS units
FROM stage_fact_sales s
JOIN dim_date d ON s.date_id = d.date_id
WHERE s.is_valid_record = 1
GROUP BY d.time_of_day
ORDER BY revenue DESC;

-- 6. Average Order Value
SELECT
    SUM(sales) / COUNT(DISTINCT order_id) AS average_order_value
FROM stage_fact_sales
WHERE is_valid_record = 1;

-- 7. Revenue by Price Band
SELECT
    p.price_band,
    SUM(s.sales) AS revenue,
    COUNT(DISTINCT s.order_id) AS orders
FROM stage_fact_sales s
JOIN dim_product p ON s.product_id = p.product_id
WHERE s.is_valid_record = 1
GROUP BY p.price_band;

-- 8. Data Validity Summary
SELECT
    is_valid_record,
    COUNT(*) AS records
FROM stage_fact_sales
GROUP BY is_valid_record;

-- 9. Duplicate Order Check
SELECT
    order_id,
    product_id,
    COUNT(*) AS duplicate_count
FROM stage_fact_sales
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

-- 10. Yearly Revenue Growth
SELECT
    d.order_year,
    SUM(s.sales) AS yearly_revenue
FROM stage_fact_sales s
JOIN dim_date d ON s.date_id = d.date_id
WHERE s.is_valid_record = 1
GROUP BY d.order_year
ORDER BY d.order_year;

-- 11. Top Cities by Units Sold
SELECT
    c.city_name,
    SUM(s.quantity) AS units_sold
FROM stage_fact_sales s
JOIN dim_city c ON s.city_id = c.city_id
WHERE s.is_valid_record = 1
GROUP BY c.city_name
ORDER BY units_sold DESC
LIMIT 10;

-- 12. Product Mix by Price Band
SELECT
    p.price_band,
    COUNT(DISTINCT s.product_id) AS unique_products,
    SUM(s.sales) AS revenue
FROM stage_fact_sales s
JOIN dim_product p ON s.product_id = p.product_id
WHERE s.is_valid_record = 1
GROUP BY p.price_band;

-- 13. Peak Order Hours
SELECT
    d.order_hour,
    COUNT(DISTINCT s.order_id) AS orders,
    SUM(s.sales) AS revenue
FROM stage_fact_sales s
JOIN dim_date d ON s.date_id = d.date_id
WHERE s.is_valid_record = 1
GROUP BY d.order_hour
ORDER BY revenue DESC;

-- 14. Top 5 Products per City
SELECT
    c.city_name,
    p.product_name,
    SUM(s.sales) AS revenue
FROM stage_fact_sales s
JOIN dim_city c ON s.city_id = c.city_id
JOIN dim_product p ON s.product_id = p.product_id
WHERE s.is_valid_record = 1
GROUP BY c.city_name, p.product_name
ORDER BY c.city_name, revenue DESC
LIMIT 50;

-- 15. Order Size Distribution
SELECT
    CASE
        WHEN quantity = 1 THEN 'Single Item'
        WHEN quantity BETWEEN 2 AND 5 THEN 'Small Order'
        WHEN quantity BETWEEN 6 AND 10 THEN 'Medium Order'
        ELSE 'Large Order'
    END AS order_size_category,
    COUNT(*) AS orders,
    SUM(sales) AS revenue
FROM stage_fact_sales
WHERE is_valid_record = 1
GROUP BY order_size_category
ORDER BY revenue DESC;

-- 16. Revenue Contribution by Top 20% Products
WITH product_revenue AS (
    SELECT product_id, SUM(sales) AS revenue
    FROM stage_fact_sales
    WHERE is_valid_record = 1
    GROUP BY product_id
),
ranked AS (
    SELECT product_id, revenue,
           NTILE(5) OVER (ORDER BY revenue DESC) AS quintile
    FROM product_revenue
)
SELECT quintile, SUM(revenue) AS total_revenue
FROM ranked
GROUP BY quintile
ORDER BY quintile;

-- 17. Invalid Records Audit
SELECT *
FROM stage_fact_sales
WHERE is_valid_record = 0
LIMIT 100;

-- 18. Revenue per Order (Distribution)
SELECT
    order_id,
    SUM(sales) AS order_revenue
FROM stage_fact_sales
WHERE is_valid_record = 1
GROUP BY order_id
ORDER BY order_revenue DESC
LIMIT 20;