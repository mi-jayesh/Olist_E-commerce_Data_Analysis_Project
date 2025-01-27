-- Question: 
-- What is the Average Order Value (AOV), and how does it vary by product category and payment method?

-- Code:

-- 1. Calculate Overall Average Order Value (AOV)
SELECT 
  round(sum(payment_value)::numeric / count(distinct o.order_id), 2) AS Average_order_value
FROM orders o 
INNER JOIN order_payments op ON o.order_id = op.order_id
WHERE order_status = 'delivered';


-- 2. Calculate AOV by Product Category
SELECT 
  product_category_name,
  round(sum(payment_value)::numeric / count(oi.order_id), 2) AS average_order_value
FROM products p
INNER JOIN order_items oi ON p.product_id = oi.product_id
INNER JOIN orders o ON o.order_id = oi.order_id
INNER JOIN order_payments op ON op.order_id = o.order_id
WHERE order_status = 'delivered'
GROUP BY product_category_name
ORDER BY 2 DESC;


-- 3. Calculate AOV by Payment Type
SELECT 
  payment_type,
  round(sum(payment_value)::numeric / count(op.order_id), 2) AS average_order_value
FROM order_payments op
INNER JOIN orders o ON op.order_id = o.order_id
WHERE order_status = 'delivered'
GROUP BY payment_type
ORDER BY 2 DESC;

-------------------------------------------------------------------------------------------------------------------------
-- Question:
-- How does the customer lifetime value (CLV) differ across product categories?

-- Customer Lifetime Value (CLTV) by Product Category
SELECT 
    p.product_category_name,
    round(SUM(op.payment_value)::numeric,2) AS total_payments,
    COUNT(DISTINCT o.order_id) AS total_orders,
    round(SUM(op.payment_value) ::numeric / COUNT(DISTINCT o.order_id),2) AS avg_order_value_per_customer,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    round(SUM(op.payment_value) ::numeric / COUNT(DISTINCT o.customer_id),2) AS avg_customer_lifetime_value
FROM customers c
INNER JOIN orders o ON o.customer_id = c.customer_id
INNER JOIN order_payments op ON o.order_id = op.order_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY avg_customer_lifetime_value DESC;


-------------------------------------------------------------------------------------------------------------------------

-- Question: 
-- How many customers have made repeated purchases, and what percentage of total sales do they contribute?

WITH repeat_cust_revenue AS (
  SELECT 
    SUM(sales) AS total_repeat_sales,
    COUNT(*) AS total_repeat_customers
  FROM (
    SELECT 
      c.customer_id, 
      SUM(op.payment_value) AS sales
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_payments op ON o.order_id = op.order_id
    WHERE order_status = 'delivered'
    GROUP BY c.customer_id
    HAVING COUNT(o.order_id) > 1
  ) cs
),

total_revenue AS (
  SELECT 
    SUM(payment_value) AS total_sales,
    COUNT(DISTINCT o.customer_id) AS total_customers
  FROM order_payments op
  INNER JOIN orders o ON o.order_id = op.order_id
  WHERE order_status = 'delivered'
)
SELECT 
 tr.total_customers,
  rr.total_repeat_customers,
  round(tr.total_sales ::numeric ,2) as total_sales,
  round(rr.total_repeat_sales :: numeric,2) as total_repeat_sales,
  ROUND((rr.total_repeat_sales::NUMERIC / tr.total_sales)::numeric * 100, 2) AS repeat_customers_perc_sales
FROM 
  total_revenue tr
CROSS JOIN 
  repeat_cust_revenue rr;
  
-------------------------------------------------------------------------------------------------------------------------

-- Question: 
-- Which product categories have the highest profit margins on Olist, and how can the company increase profitability across different categories?

select 
  product_category_name,
  ROUND(((sum(payment_value) - sum(freight_value)) / sum(payment_value))::numeric * 100,2) as Profit_Margin
from products p 
inner join order_items oi on oi.product_id = p.product_id
inner join orders o on o.order_id = oi.order_id
inner join order_payments op on op.order_id = o.order_id
where order_status = 'delivered'
group by product_category_name 
order by 2 desc;
  
-------------------------------------------------------------------------------------------------------------------------

-- Question:
-- Which payment methods are most commonly used by Olist customer

select 
   payment_type,
   count(order_id) as Number_of_payments,
   round((count(order_id) / sum(count(order_id)) over ()) ::numeric * 100,2) as percentage_of_orders
from order_payments
group by payment_type
order by 2 desc;

-------------------------------------------------------------------------------------------------------------------------

-- Question:
-- What are the most popular product categories on Olist, and how do their sales volumes compare to each other?

SELECT 
  p.product_category_name,
  COUNT(oi.order_id) AS total_orders,
  round(SUM(oi.price)::numeric,2) AS total_sales,
  ROUND((SUM(oi.price)/ SUM(SUM(oi.price)) OVER()) :: numeric * 100, 2) AS sales_percentage
FROM 
  products p
INNER JOIN 
  order_items oi ON p.product_id = oi.product_id
INNER JOIN 
  orders o ON o.order_id = oi.order_id
WHERE 
  o.order_status = 'delivered'
GROUP BY 
  p.product_category_name
ORDER BY 
  sales_percentage DESC;

-------------------------------------------------------------------------------------------------------------------------

-- Question:
-- What percentage of orders on Olist experience late deliveries, and how does this impact customer satisfaction and operational efficiency?

SELECT 
    total_delivered_orders,
    before_estimated_delivery_date_count,
    ROUND((before_estimated_delivery_date_count::numeric / total_delivered_orders) * 100, 2) AS Before_Estimated_Date_Delivery_Percentage,
    late_delivery_count,
    ROUND((late_delivery_count::numeric / total_delivered_orders) * 100, 2) AS Late_Delivery_Percentage
FROM (
    SELECT 
        SUM(CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date 
            THEN 1 ELSE 0 END) AS late_delivery_count,
        SUM(CASE
            WHEN order_delivered_customer_date < order_estimated_delivery_date 
            THEN 1 ELSE 0 END) AS before_estimated_delivery_date_count,
        COUNT(order_id) AS total_delivered_orders
    FROM orders
    WHERE order_status = 'delivered'
) AS x;

-- let's review rating for late deliveries

select 
  round(avg(review_score),2) as average_rating,
  round(max(review_score),2) as max_rating,
  round(min(review_score),2) as min_rating
from reviews r
inner join orders o on o.order_id = r.order_id
where order_delivered_customer_date > order_estimated_delivery_date;

-------------------------------------------------------------------------------------------------------------------------

-- Question:
-- What is the overall order cancellation rate on Olist, and which factors (e.g., product categories, customer demographics, order size) contribute most to cancellations?

SELECT 
    COUNT(order_id) AS total_order_cnt,
    SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END) AS canceled_order_count,
    ROUND((SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END) :: numeric / COUNT(order_id)) * 100, 2) AS canceled_order_percentage
FROM orders;

-------------------------------------------------------------------------------------------------------------------------

-- Question:
-- What is the average number of days it takes for orders in each product category to be delivered, and how can this information be used to improve inventory management and customer satisfaction?
SELECT 
    p.product_category_name,
    ROUND(AVG(DATE_PART('day', o.order_estimated_delivery_date - o.order_purchase_timestamp))::NUMERIC,2) AS avg_days_to_delivery
FROM orders o
INNER JOIN order_items oi ON oi.order_id = o.order_id
INNER JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status != 'canceled' 
  AND o.order_status != 'undefined'
GROUP BY p.product_category_name
ORDER BY 2 DESC;

-------------------------------------------------------------------------------------------------------------------------
-- Question"
-- Which product categories have the highest average customer review scores for delivered orders, and how do they compare to each other?
SELECT 
    p.product_category_name,
    ROUND(AVG(review_score) :: NUMERIC ,2) as Average_review_score
FROM products p
INNER JOIN order_items oi on oi.product_id = p.product_id
INNER JOIN reviews r on r.order_id = oi.order_id
INNER JOIN orders o on o.order_id = r.order_id
WHERE o.order_status = 'delivered' 
GROUP BY p.product_category_name
ORDER BY 2 DESC;

-------------------------------------------------------------------------------------------------------------------------







