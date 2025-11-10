# SQL DataWarehouse and Analytics Project
### 1: Building the Data Warehouse
- Data Sources: Data from two source systems (ERP & CRM) (CSV files).
- Process: Built ETL pipelines to extract, transform, and load data; modeled fact and dimension tables using star schema; ensured data quality and consistency across layers.
- Purpose:  Developed the Gold Layer as the business-level data representation, structured to support analytical and
 reporting use cases
### 2. Analytical Components
#### 2.1 Sales Performance Over Time
- Analyze sales trends across different time granularities: by year, by month, by year-month
    - 2013 showed a sales explosion, followed by a sharp decline.
    - December is the strongest month due to holidays and February is the worst performance.
#### 2.2 Cumilative Analysis
- Calculate the total sales per month and the running total of sales over time
- Observe growth trends overtime
- Techniques used: date function, window functions
#### 2.3 Product Performance Analysis
- Comparing each product's sales to both its average sales performance and the previous year's sale
- Identify above/below average performers and detect increase or decrease trends
- Techniques used: window functions: Lag(), Avg()
#### 2.4 Part-to-Whole Analysis
- Bikes contribute most to total sales (96.46%)
- Clothing and Accessories make up a tiny portion of the total sales.
#### 2.5 Data Segmentation
- Segment customers based on lifespan and total spending.
- Products are grouped into cost ranges.
### 3. Customer Report (View Creation)
- Creates a reusable view consolidates key customer metrics and behaviors
- Includes:
  - Customer demographics (name, age, age group)
  - Behavioral metrics: lifespan, recency, avg_order_value, avg_monthly_spend
  - Segmentation labels: VIP, Regular, New
