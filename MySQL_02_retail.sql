
#----------Retail Data anlysis using MySQL------------

# Create the table we need in the database

CREATE TABLE retail_sales_dataset( 
    transaction_ID int NOT NULL AUTO_INCREMENT, 
    date varchar(100) ,  
    Customer_ID varchar(100) ,  
    gender varchar(100) ,
    age varchar(100) ,
    Product_category varchar(100) ,
    quantity varchar(100) ,
    price_per_unit varchar(100) ,
    total_amount varchar(100), 
    
    PRIMARY KEY (transaction_ID)  
);  


select * from retail_sales_dataset rsd 

#Common analysis

#1 Find the years and months we have in the dataset

select
year(str_to_date(date, '%m/%d/%Y')) as Year,
month(str_to_date(date, '%m/%d/%Y')) as Month

from retail_sales_dataset 
group by 1,2 
order by 1 asc 



#How do I calculate the total amount spent per product category?
SELECT Product_category, SUM(total_amount) AS total_spent
FROM retail_sales_dataset
GROUP BY Product_category;


#How can I calculate the average age of customers for each gender?

SELECT gender, round(AVG(age),0)  AS average_age
FROM retail_sales_dataset
GROUP BY gender;

#How can I find the total number of transactions by gender?

SELECT gender, COUNT(transaction_ID) AS total_transactions
FROM retail_sales_dataset
GROUP BY gender;

# How can I calculate the average total amount spent per customer?
select Customer_ID, avg(total_amount) as avg_total_amt  
from retail_sales_dataset
group by 1


# Price Per Unit Analysis

# How can I retrieve the highest and lowest price_per_unit for each product category?

SELECT Product_category,
MAX(price_per_unit) AS highest_price,
MIN(price_per_unit) AS lowest_price
FROM retail_sales_dataset
GROUP BY Product_category;

#Top Products

#How do I find the most purchased product based on quantity?

select Product_category, sum(quantity) as Qty
FROM retail_sales_dataset
group by 1
order by 2 desc  
limit 1

#Customer Spending Patterns
#How can I find the top 10 customers who spent the most?

select Customer_ID, sum(total_amount) as Amt 
FROM retail_sales_dataset
group by 1
order by 2 desc 
limit 10

#Percentage Contribution

#How do I calculate the percentage contribution of each product category to the total revenue?

SELECT Product_category,
concat( cast(round((SUM(total_amount) / (SELECT SUM(total_amount)FROM retail_sales_dataset)) * 100,2)as CHAR),'%')  AS percentage_contribution
FROM retail_sales_dataset
GROUP BY 1
order by 2 desc 

#CTE comprehensive analysis

#1. Top 3 Products per Customer (By Total Amount Spent)
#This query finds the top 3 products per customer based on the total amount spent.

WITH ProductTotals AS (
  SELECT Customer_ID, Product_category, SUM(total_amount) AS total_spent
  FROM retail_sales_dataset
  GROUP BY Customer_ID, Product_category
),
RankedProducts AS (
  SELECT Customer_ID, Product_category, total_spent,
         ROW_NUMBER() OVER (PARTITION BY Customer_ID ORDER BY total_spent DESC) AS rnk
  FROM ProductTotals
)
SELECT Customer_ID, Product_category, total_spent
FROM RankedProducts
WHERE rnk <= 3
order by 3 desc 
;

#2. Customers with Above Average Spending
#Find customers who spent more than the average total amount across all customers.

WITH AverageSpending AS (
  SELECT AVG(total_amount) AS avg_spent
  FROM retail_sales_dataset
)
SELECT Customer_ID, SUM(total_amount) AS total_spent
FROM retail_sales_dataset
GROUP BY Customer_ID
HAVING SUM(total_amount) > (SELECT avg_spent FROM AverageSpending);

#3. Customer Age Group Analysis
#This query groups customers into different age ranges and calculates the total amount spent by each age group.

WITH AgeGroups AS (
  SELECT Customer_ID, 
         CASE 
           WHEN age < 20 THEN 'Under 20'
           WHEN age BETWEEN 20 AND 30 THEN '20-30'
           WHEN age BETWEEN 31 AND 40 THEN '31-40'
           WHEN age BETWEEN 41 AND 50 THEN '41-50'
           ELSE 'Above 50'
         END AS age_group,
         SUM(total_amount) AS total_spent
  FROM retail_sales_dataset
  GROUP BY Customer_ID, age
)
SELECT age_group, SUM(total_spent) AS total_spent_by_group
FROM AgeGroups
GROUP BY age_group;


#4. Product Performance Trend Over Time
#Track how well each product is performing (total quantity sold) over time, using the date column for time analysis.

WITH MonthlySales AS (
  SELECT Product_category, 
         format(date, '%Y-%m') AS month, 
         SUM(quantity) AS total_quantity_sold
  FROM retail_sales_dataset
  GROUP BY Product_category, month
)
SELECT Product_category, month, total_quantity_sold
FROM MonthlySales
ORDER BY Product_category, month;

#5. Customer Retention (Customers Making Multiple Purchases)
#This query finds customers who have made more than one transaction and calculates their total spending.

WITH CustomerTransactions AS (
  SELECT Customer_ID, COUNT(transaction_ID) AS transaction_count, SUM(total_amount) AS total_spent
  FROM retail_sales_dataset
  GROUP BY Customer_ID
)
SELECT Customer_ID, total_spent
FROM CustomerTransactions
WHERE transaction_count > 1;

#6. Top Customers and Their Average Product Quantity
#Find the top 5 customers by total amount spent and calculate the average quantity of products they purchased.

WITH CustomerSpending AS (
  SELECT Customer_ID, SUM(total_amount) AS total_spent
  FROM retail_sales_dataset
  GROUP BY Customer_ID
),
TopCustomers AS (
  SELECT Customer_ID, total_spent, RANK() OVER (ORDER BY total_spent DESC) AS rnk
  FROM CustomerSpending
)
SELECT t.Customer_ID, t.total_spent, AVG(tr.quantity) AS avg_quantity_purchased
FROM TopCustomers t
JOIN retail_sales_dataset tr ON t.Customer_ID = tr.Customer_ID
WHERE t.rnk <= 5
GROUP BY t.Customer_ID, t.total_spent;

#7. Gender-Based Product Preferences
#Analyze the product preferences of customers by gender and see which products each gender tends to buy the most.

WITH ProductGender AS (
  SELECT gender, Product_category, SUM(quantity) AS total_quantity_sold
  FROM retail_sales_dataset
  GROUP BY gender, Product_category
),
RankedProducts AS (
  SELECT gender, Product_category, total_quantity_sold,
         RANK() OVER (PARTITION BY gender ORDER BY total_quantity_sold DESC) AS rnk
  FROM ProductGender
)
SELECT gender, Product_category, total_quantity_sold
FROM RankedProducts
WHERE rnk = 1;

#8. Yearly Revenue Growth
#Calculate the year-over-year revenue growth based on the date column.

WITH YearlyRevenue AS (
  SELECT YEAR(date) AS year, SUM(total_amount) AS total_revenue
  FROM retail_sales_dataset
  GROUP BY YEAR(date)
),
RevenueGrowth AS (
  SELECT year, total_revenue, 
         LAG(total_revenue) OVER (ORDER BY year) AS previous_year_revenue
  FROM YearlyRevenue
)
SELECT year, total_revenue, 
       (total_revenue - previous_year_revenue) / previous_year_revenue * 100 AS revenue_growth_percentage
FROM RevenueGrowth
WHERE previous_year_revenue IS NOT NULL;


#9. Customer Churn Prediction (No Purchase in Last 6 Months)
#Identify customers who haven’t made a purchase in the last 6 months and could be potential churn risks.

WITH LastPurchaseDate AS (
  SELECT Customer_ID, MAX(date) AS last_purchase_date
  FROM retail_sales_dataset
  GROUP BY Customer_ID
)
SELECT Customer_ID, last_purchase_date
FROM LastPurchaseDate
WHERE last_purchase_date < CURDATE() - INTERVAL 6 MONTH;

#10. Average Price per Unit for Each Product Category
#Calculate the average price per unit for each product category.

WITH AvgPricePerUnit AS (
  SELECT Product_category, AVG(price_per_unit) AS avg_price_per_unit
  FROM retail_sales_dataset
  GROUP BY Product_category
)
SELECT Product_category, avg_price_per_unit
FROM AvgPricePerUnit
ORDER BY avg_price_per_unit DESC;






















































