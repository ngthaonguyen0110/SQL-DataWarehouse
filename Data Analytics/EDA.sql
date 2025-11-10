-- Sale performance over time
--Theo năm
SELECT
	YEAR(order_date) AS ORDER_YEAR,
	SUM(sales_amount) AS TOTAL_SALES,
	COUNT(DISTINCT customer_key ) AS TOTAL_CUSTOMERS,
	SUM(QUANTITY) AS TOTAL_QUANTITY
FROM [gold].[fact_sales]
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)
-- 2013 là năm có doanh số bùng nổ rồi giảm mạnh sau đó

-- Theo tháng
SELECT
	MONTH(order_date) AS ORDER_MONTH,
	SUM(sales_amount) AS TOTAL_SALES,
	COUNT(DISTINCT customer_key ) AS TOTAL_CUSTOMERS,
	SUM(QUANTITY) AS TOTAL_QUANTITY
FROM [gold].[fact_sales]
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date)

-- Tháng cao điểm là tháng 12 mùa lễ hội năm mới, giáng sinh, tháng tệ nhất là tháng 2


SELECT
	FORMAT(order_date,'yyyy-MM') AS ORDER_TIME,
	SUM(sales_amount) AS TOTAL_SALES,
	COUNT(DISTINCT customer_key ) AS TOTAL_CUSTOMERS,
	SUM(QUANTITY) AS TOTAL_QUANTITY
FROM [gold].[fact_sales]
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date,'yyyy-MM')
ORDER BY FORMAT(order_date,'yyyy-MM')


-- CUMULATIVE ANALYSIS
-- Calculate the total sales per month and the running total of sales over time

SELECT
ORDER_YEAR,
TOTAL_SALES,
SUM(TOTAL_SALES) OVER( ORDER BY ORDER_YEAR) AS RUNNING_TOTAL_SALES,
AVG(AVG_PRICE) OVER( ORDER BY ORDER_YEAR) AS MOVING_AVG_PRICE
FROM (
SELECT 
DATETRUNC(YEAR,order_date) AS ORDER_YEAR,
SUM(sales_amount) AS TOTAL_SALES,
AVG([price]) AS AVG_PRICE
FROM [gold].[fact_sales]
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR,order_date)
) A


SELECT
ORDER_DATE,
TOTAL_SALES,
SUM(TOTAL_SALES) OVER(PARTITION BY ORDER_DATE ORDER BY ORDER_DATE) AS RUNNING_TOTAL_SALES
FROM (
SELECT 
DATETRUNC(MONTH,order_date) AS ORDER_DATE,
SUM(sales_amount) AS TOTAL_SALES
FROM [gold].[fact_sales]
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH,order_date)
) A

-- PERFORMANCE ANALYSIS
-- Comparing each product's sales to both its average sales performance àn the previois year's sale
WITH yearly_product_sale AS (
	SELECT
	YEAR(F.order_date) AS ORDER_YEAR,
	P.product_name AS PRODUCT_NAME,
	SUM(F.sales_amount) AS CURRENT_SALE
	FROM [gold].[fact_sales] F
	LEFT JOIN [gold].[dim_products] P
	ON F.product_key=P.product_key
	WHERE F.order_date IS NOT NULL
	GROUP BY YEAR(F.order_date),
			P.product_name
			)
SELECT 
ORDER_YEAR,
product_name,
CURRENT_SALE,
AVG(CURRENT_SALE) OVER(PARTITION BY product_name) AS AVG_SALE,
CURRENT_SALE-AVG(CURRENT_SALE) OVER(PARTITION BY product_name) AS DIFF_AVG,
CASE WHEN CURRENT_SALE-AVG(CURRENT_SALE) OVER(PARTITION BY product_name) > 0 THEN 'Above aver' 
	 WHEN CURRENT_SALE-AVG(CURRENT_SALE) OVER(PARTITION BY product_name) = 0 THEN 'Avg'
ELSE 'Below aver'
END AS AVG_CHANGE,
LAG(CURRENT_SALE) OVER(PARTITION BY product_name ORDER BY ORDER_YEAR) AS PREVIOUS_SALE,
CURRENT_SALE-LAG(CURRENT_SALE) OVER(PARTITION BY product_name ORDER BY ORDER_YEAR) AS DIFF_PRE,
CASE WHEN CURRENT_SALE-LAG(CURRENT_SALE) OVER(PARTITION BY product_name ORDER BY ORDER_YEAR) > 0 THEN 'Increase' 
	 WHEN CURRENT_SALE-LAG(CURRENT_SALE) OVER(PARTITION BY product_name ORDER BY ORDER_YEAR) < 0 THEN 'Decrease'
ELSE 'No change'
END AS PRE_CHANGE
FROM yearly_product_sale
ORDER BY product_name, ORDER_YEAR

--PART TO WHOLE
--Which categories contribute the most to overall sales?
WITH category_sale AS (
SELECT 
category,
SUM(sales_amount) AS TOTAL_SALES
FROM [gold].[fact_sales] F
LEFT JOIN [gold].[dim_products] P
ON F.product_key=P.product_key
GROUP BY category
)
SELECT 
category,
TOTAL_SALES,
SUM(TOTAL_SALES) OVER() AS OVERALL_SALE,
CONCAT(ROUND(CAST(TOTAL_SALES AS FLOAT)/SUM(TOTAL_SALES) OVER()*100 ,2), '%')AS PCT
FROM category_sale

-- DATA SEGMENTATION
-- Segment products into cost ranges and count how many products fall into each segment
;WITH product_segment AS (
SELECT 
product_key,
product_name,
CASE WHEN cost <100 THEN 'Below 100'
	WHEN COST BETWEEN 100 AND 500 THEN '100-500'
	WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	ELSE 'Above 1000'
END COST_RANGE
FROM [gold].[dim_products]
) 
SELECT COST_RANGE,
		COUNT(product_key) AS TOTAL_PRODUCT
FROM product_segment
GROUP BY COST_RANGE
ORDER BY COUNT(product_key) DESC

-- Group customers into 3 segments based on their spending behavior
	-- VIP: at least 12 months of history and spending mote than 5000
	-- Regular: at least 12 months of history and spending 5000 or less
	-- New: lifespan less than 12 months
WITH customer_spending AS (
SELECT
C.customer_key,
SUM(F.sales_amount) AS TOTAL_SPENDING,
MIN(order_date) AS FIRST_ORDER,
MAX(order_date) AS LAST_ORDER,
DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS LIFESPAN
FROM [gold].[fact_sales] F
LEFT JOIN [gold].[dim_customers] C
ON F.customer_key=C.customer_key
GROUP BY C.customer_key
)
SELECT 
CUSTOMER_SEGMENT,
COUNT(CUSTOMER_KEY) AS TOTAL_CUSTOMERS
FROM (
	SELECT 
	customer_key,
	TOTAL_SPENDING,
	LIFESPAN, 
	CASE WHEN LIFESPAN >= 12 AND TOTAL_SPENDING >5000 THEN 'VIP'
		 WHEN LIFESPAN >= 12 AND TOTAL_SPENDING <=5000 THEN 'Regular'
		 ELSE 'New'
	END AS CUSTOMER_SEGMENT
	FROM customer_spending
) X
GROUP BY CUSTOMER_SEGMENT
ORDER BY COUNT(CUSTOMER_KEY) DESC

--
