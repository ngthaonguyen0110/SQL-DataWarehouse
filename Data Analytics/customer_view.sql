/*
===========================================================================
Customer Report
===========================================================================
Purpose:
- This report consolidates key customer metrics and behaviors

Highlights:
	1. Gather essential fields such as names, ages, and transaction details
	2. Segments customers into categories (VIP, Regular, New) and age groups
	3. Aggregates customer level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- tatal products
		- lifespan (month)
	4. Calculates valuable KPIs:
		- recency (months since last order)
		- average order value
		- average monthly spend
===========================================================================
*/

CREATE VIEW gold.report_customer as
WITH base_query as (
-- 1 Retrieves core columns 
SELECT
f.order_number,
f.product_key, 
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
--c.first_name,
--c.last_name,
CONCAT(c.first_name, ' ',c.last_name) as customer_name,
--c.birthdate,
DATEDIFF(Year, c.birthdate, GETDATE()) as Age
FROM [gold].[fact_sales] f
LEFT JOIN [gold].[dim_customers] c
on f.customer_key=c.customer_key
where order_date IS NOT NULL	
)

, customer_aggregation as (
--2 Customer Aggragations
SELECT
customer_key,
customer_number,
customer_name,
age,
count(distinct order_number) as total_orders,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity,
count(distinct product_key) as total_products,
max(order_date) as last_order_date,
DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS LIFESPAN

FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age
)
SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE WHEN age <20 THEN 'Under 20'
		WHEN age BETWEEN 20 and 29 THEN '20-29'
		WHEN age BETWEEN 30 and 39 THEN '30-39'
		WHEN age BETWEEN 40 and 49 THEN '40-49'
		ELSE '50 and above'
	END AS age_group,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	LIFESPAN,
	CASE WHEN LIFESPAN >= 12 AND total_sales >5000 THEN 'VIP'
		WHEN LIFESPAN >= 12 AND total_sales <=5000 THEN 'Regular'
		ELSE 'New'
	END AS CUSTOMER_SEGMENT,
	last_order_date,
	DATEDIFF(month, last_order_date, GETDATE()) as recency, -- How many months from the last order
	-- Compuate average order value
	CASE WHEN total_orders=0 THEN 0
	ELSE
		total_sales/total_orders 
	END AS avg_order_value,
	-- Compuate average monthly spend
	CASE WHEN LIFESPAN=0 then total_sales
		ELSE  total_sales/LIFESPAN
	END AS avg_monthly_spend
FROM customer_aggregation


