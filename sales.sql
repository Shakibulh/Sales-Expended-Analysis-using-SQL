create database sales;
use sales;

# total sales amount
SELECT SUM(total_sale) AS total_revenue
FROM retail_sales;

# Gender Count
SELECT gender, COUNT(*) AS customer_count
FROM retail_sales
GROUP BY gender;

# Transaction per city
SELECT city, COUNT(*) AS total_transactions
FROM retail_sales
GROUP BY city
ORDER BY total_transactions DESC;

# Avarage sales per catagorey
SELECT category, ROUND(AVG(total_sale), 2) AS avg_sale
FROM retail_sales
GROUP BY category;

# Sales per Payment Method
SELECT payment_method, SUM(total_sale) AS total_sales
FROM retail_sales
GROUP BY payment_method
ORDER BY total_sales DESC;

# Top sales for month
SELECT 
    EXTRACT(MONTH FROM sale_date) AS month,
    SUM(total_sale) AS total_sales
FROM retail_sales
GROUP BY month
ORDER BY total_sales DESC;



####  find the top 3 cities with the highest average total sales per transaction for VIP customers only, and show the total number of transactions, average quantity, and most popular payment method used in each of those cities
WITH city_stats AS (
    SELECT
        city,
        COUNT(*) AS total_transactions,
        AVG(quantity) AS avg_quantity,
        AVG(total_sale) AS avg_total_sale,
        payment_method,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY COUNT(*) DESC) AS payment_rank
    FROM retail_sales
    WHERE customer_segment = 'VIP'
    GROUP BY city, payment_method
),
top_cities AS (
    SELECT city, total_transactions, avg_quantity, avg_total_sale
    FROM (
        SELECT DISTINCT city, total_transactions, avg_quantity, avg_total_sale
        FROM city_stats
    ) sub
    ORDER BY avg_total_sale DESC
    LIMIT 3
),
popular_payments AS (
    SELECT city, payment_method
    FROM city_stats
    WHERE payment_rank = 1
)
SELECT 
    t.city,
    t.total_transactions,
    ROUND(t.avg_quantity, 2) AS avg_quantity,
    ROUND(t.avg_total_sale, 2) AS avg_total_sale,
    p.payment_method AS most_popular_payment_method
FROM top_cities t
JOIN popular_payments p ON t.city = p.city;


# Calculate the total spending (SUM(total_sale)) of each customer, and rank them within their city.
SELECT 
    customer_id,
    city,
    SUM(total_sale) AS total_spent,
    RANK() OVER (PARTITION BY city ORDER BY SUM(total_sale) DESC) AS city_rank
FROM retail_sales
GROUP BY customer_id, city;


# High-Value Transaction Pattern

SELECT 
    payment_method,
    COUNT(*) AS high_value_txns,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage_of_total
FROM retail_sales
WHERE total_sale > 1000
GROUP BY payment_method;

# Weekend vs Weekday Sales
# Monthly Sales Trend by Category
SELECT 
    DATE_FORMAT(sale_date, '%Y-%m-01') AS month,
    category,
    SUM(total_sale) AS monthly_sales
FROM retail_sales
WHERE sale_date >= (
    SELECT MAX(sale_date) FROM retail_sales
) - INTERVAL 6 MONTH
GROUP BY month, category
ORDER BY month DESC, category;

# Most Consistent VIP Customers

WITH vip_txns AS (
    SELECT 
        customer_id,
        DATE_FORMAT(sale_date, '%Y-%m-01') AS sale_month
    FROM retail_sales
    WHERE customer_segment = 'VIP'
        AND sale_date >= '2023-06-12'  -- 6 months before max(sale_date)
    GROUP BY customer_id, sale_month
),
monthly_count AS (
    SELECT customer_id, COUNT(DISTINCT sale_month) AS active_months
    FROM vip_txns
    GROUP BY customer_id
)
SELECT customer_id
FROM monthly_count
WHERE active_months = 6;

SELECT DISTINCT customer_id
FROM retail_sales
WHERE customer_segment = 'VIP'
  AND sale_date >= '2023-06-12';






