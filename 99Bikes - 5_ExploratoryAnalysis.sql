USE Portfolio_Sales_99Bikes
GO

/* EXPLORATORY DATA ANALYSIS */

/* Summary statistics */

SELECT * FROM tblTransactions

-- We are interested only in the orders that have been completed
-- We have to take into consideration that some orders have not been completed

-- Total sales and profit
SELECT 
    SUM(list_price) AS Sales_Total,
    SUM(list_price) - SUM(standard_cost) AS Profit_Total
FROM tblTransactions 
WHERE order_status = 'Approved'

-- Online vs. shops sales
SELECT online_order, 
       SUM(list_price) AS Sales_by_Online
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY online_order
-- no difference

-- Sales & Profit by product 
SELECT product_id, 
       SUM(list_price) AS Sales_by_Product
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY product_id
ORDER BY Sales_by_Product DESC
-- top 3 selling products: 3, 0, 38
SELECT product_id, 
       SUM(list_price) - SUM(standard_cost) AS Profit_by_Product
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY product_id
ORDER BY Profit_by_Product DESC
-- top 3 profitable products: 3, 38, 57

-- Sales & Profit by brand
SELECT brand, 
       SUM(list_price) AS Sales_by_Brand
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY brand
ORDER BY Sales_by_Brand DESC
-- Top 3 selling brand: Solex, WeareA2B, Giant Bicycles
SELECT brand, 
       SUM(list_price) - SUM(standard_cost) AS Profit_by_Brand
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY brand
ORDER BY Profit_by_Brand DESC
-- Top 3 profitable brands: WeareA2B, Solex, Trek Bycicles

-- Sales & Profit by class
SELECT product_class, 
       SUM(list_price) AS Sales_by_Class
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY product_class
ORDER BY Sales_by_Class DESC
-- Top selling class: Medium
SELECT product_class, 
       SUM(list_price) - SUM(standard_cost) AS Profit_by_Class
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY product_class
ORDER BY Profit_by_Class DESC
-- Top profitable class:Medium

-- Sales & Profit by class
SELECT product_class, 
       SUM(list_price) AS Sales_by_Class
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY product_class
ORDER BY Sales_by_Class DESC
-- Top selling class: Medium
SELECT product_class, 
       SUM(list_price) - SUM(standard_cost) AS Profit_by_Class
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY product_class
ORDER BY Profit_by_Class DESC
-- Top profitable class: Medium

-- Sales & Profit by size
SELECT product_size, 
       SUM(list_price) AS Sales_by_Size
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY product_size
ORDER BY Sales_by_Size DESC
-- Top selling size: Medium
SELECT product_size, 
       SUM(list_price) - SUM(standard_cost) AS Profit_by_Size
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY product_size
ORDER BY Profit_by_Size DESC
-- Top profitable size: Medium

-- Sales by longevity
SELECT YEAR(product_first_sold_date) AS Year_First_Sold,
       SUM(list_price) AS Sales_by_Longevity
FROM tblTransactions
WHERE order_status = 'Approved' AND product_longevity IS NOT NULL 
GROUP BY YEAR(product_first_sold_date)
ORDER BY Sales_by_Longevity DESC



/* Trend analysis over time */

-- Months of the year
SELECT MONTH(transaction_date) AS Transaction_Month,
       SUM(list_price) AS Sales_by_Month
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY MONTH(transaction_date)
ORDER BY Sales_by_Month DESC
-- top 3 selling months: October, August, May (no big differences)

SELECT Seasons, 
       SUM(list_price) AS Sales_by_Season
FROM 
(SELECT *,
       CASE 
              WHEN MONTH(transaction_date) BETWEEN 3 AND 5 THEN 'Spring'
              WHEN MONTH(transaction_date) BETWEEN 6 AND 8 THEN 'Summer'
              WHEN MONTH(transaction_date) BETWEEN 9 AND 11 THEN 'Autumn'
              ELSE 'Winter'
       END AS Seasons
FROM tblTransactions) Seasons_Subquery
GROUP BY Seasons
ORDER BY Sales_by_Season DESC
-- top selling season: summer (but no big difference, all fairly similar)



/* Customer segmentation */


-- Gender

SELECT D.gender
       , COUNT(*) AS Count_Gender
       , SUM(T.list_price) AS Sales_by_Gender
FROM tblDemographics AS D 
       LEFT JOIN tblTransactions AS T ON D.customer_id = T.customer_id
WHERE T.order_status = 'Approved'
GROUP BY D.gender
-- similar data


-- Age 

SELECT D.age_group
       , COUNT(*) AS Count_Age_Group
       , SUM(T.list_price) AS Sales_by_Age_Group
FROM tblDemographics AS D 
       LEFT JOIN tblTransactions AS T ON D.customer_id = T.customer_id
WHERE T.order_status = 'Approved'
GROUP BY D.age_group
ORDER BY Sales_by_Age_Group DESC
-- Established professionals are by far the most-buying category, 
-- but are they buying more expenisve products or are they buying more or are there more customers in this age group?

-- Counting how many customers we have for each age group
SELECT age_group
       , COUNT(*) AS Count_Age_Group_Demographics
FROM tblDemographics
GROUP BY age_group
ORDER BY Count_Age_Group_Demographics DESC
-- Established professionals are almost twice as many as 2nd age group (mature professionals)

-- Counting how many transactions we have per customer for each age group:
--1. We need a subquery to count the transactions per customer 
SELECT customer_id
       , COUNT(*) AS Transaction_Per_Customer
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY customer_id
--2. We calculate the average of the count per age group, joining the subquery with the Demographics table
SELECT D.age_group
       , AVG(Transaction_Per_Customer) AS Transaction_Per_Customer_By_Age_Group
FROM
[dbo].[tblDemographics] AS D 
       LEFT JOIN (SELECT customer_id, COUNT(*) AS Transaction_Per_Customer
                  FROM tblTransactions
                  WHERE order_status = 'Approved'
                  GROUP BY customer_id) Count_Transaction_Subquery 
       ON D.customer_id = Count_Transaction_Subquery.customer_id
GROUP BY D.age_group
ORDER BY Transaction_Per_Customer_By_Age_Group DESC 
-- Established professionals are not the customers that make more transactions (it's Young Seniors)
-- However, the average number of transactions is fairly similar among age groups

-- Calculating how much customers in different age groups spend on average 
--1. Calculating average money spent per transaction for each customer
SELECT customer_id
       , AVG(list_price) AS Amount_Per_Customer 
FROM tblTransactions
WHERE order_status = 'Approved'
GROUP BY customer_id
--2. Calculating the average per age group
SELECT D.age_group
       , AVG(Amount_Per_Customer) AS Amount_Per_Customer_By_Age_Group
FROM
[dbo].[tblDemographics] AS D 
       LEFT JOIN (SELECT customer_id, AVG(list_price) AS Amount_Per_Customer 
                  FROM tblTransactions
                  WHERE order_status = 'Approved'
                  GROUP BY customer_id) Avg_Amount_Subquery 
       ON D.customer_id = Avg_Amount_Subquery.customer_id
GROUP BY D.age_group
ORDER BY Amount_Per_Customer_By_Age_Group DESC 
-- Young Seniors are the ones who spend the most money per transaction

-- Adding this data to the tables for further analysis in data visualization programs
--1. Number of transactions per customer 
--1.1. Calculating the count per customer
SELECT customer_id, COUNT(*) OVER (PARTITION BY customer_id) AS Transaction_Count
FROM tblTransactions 
WHERE order_status = 'Approved'
--1.2. Creating the new column
ALTER TABLE [dbo].[tblTransactions]
ADD customer_transaction_count int 
GO
--1.3. Setting the values using a subquery to calculate the count and joining it to tblTransaction to macth the customer_id
begin tran
UPDATE [dbo].[tblTransactions] 
SET customer_transaction_count = Transaction_Count 
                                 FROM (
                                   SELECT customer_id, 
                                          COUNT(*) OVER (PARTITION BY customer_id) AS Transaction_Count
                                   FROM tblTransactions
                                   WHERE order_status = 'Approved') T_Count_Sub 
                                 JOIN tblTransactions AS T ON T_Count_Sub.customer_id = T.customer_id
GO
-- Checking if it worked properly
SELECT customer_id, customer_transaction_count FROM tblTransactions GROUP BY customer_id, customer_transaction_count
SELECT customer_id, customer_transaction_count FROM tblTransactions WHERE order_status <> 'Approved' 
commit tran

--2. Average transaction amount per customer
--2.1. Calculating the average amount per customer
SELECT customer_id, AVG(list_price) OVER (PARTITION BY customer_id) AS Transaction_Avg_Amount
FROM tblTransactions 
WHERE order_status = 'Approved'
--2.2. Creating the new column
ALTER TABLE [dbo].[tblTransactions]
ADD customer_transaction_avg_amount smallmoney 
GO 
--2.3. Setting the values using a subquery to calculate the average and joining it to tblTransaction to macth the customer_id
begin tran 
UPDATE [dbo].[tblTransactions]
SET customer_transaction_avg_amount = Transaction_Avg_Amount 
                                      FROM (
                                          SELECT customer_id,
                                                 AVG(list_price) OVER (PARTITION BY customer_id) AS Transaction_Avg_Amount
                                          FROM tblTransactions 
                                          WHERE order_status = 'Approved') T_Avg_Amount_Sub
                                      JOIN tblTransactions AS T ON T_Avg_Amount_Sub.customer_id = T.customer_id
GO 
-- Checking if it worked properly
SELECT customer_id, customer_transaction_avg_amount FROM tblTransactions GROUP BY customer_id, customer_transaction_avg_amount
SELECT customer_id, customer_transaction_avg_amount FROM tblTransactions WHERE order_status <> 'Approved' 
commit tran 


-- Geographical area 

SELECT DISTINCT(country)
FROM tblCustomerAddress
-- All customers are from Australia

SELECT DISTINCT([state]) 
FROM tblCustomerAddress
-- We have 3 states
SELECT [state], 
       COUNT(*) AS Customers_per_State
FROM tblCustomerAddress
GROUP BY [state]
ORDER BY Customers_per_State DESC
-- In New South Wales there are twice as many customers as in the other states 
SELECT CA.[state],
       SUM(T.list_price) AS Sales_By_State,
       COUNT(*) AS Transactions_By_State
FROM tblCustomerAddress AS CA 
       LEFT JOIN tblTransactions AS T ON CA.customer_id = T.customer_id
WHERE T.order_status = 'Approved'
GROUP BY CA.[state]
ORDER BY Sales_By_State DESC
-- New South Wales also shows the highest sales

SELECT DISTINCT(postcode)
FROM tblCustomerAddress
-- We have 873 postcodes
SELECT [state],
       [postcode], 
       COUNT(*) AS Customers_per_Postcode
FROM tblCustomerAddress
GROUP BY [state], [postcode]
ORDER BY Customers_per_Postcode DESC
-- Top 10 postcodes for number of customers are all in New South Wales, except for 3977 (Victoria)
SELECT CA.[state],
       CA.postcode,
       SUM(T.list_price) AS Sales_By_Postcode,
       COUNT(*) AS Transactions_By_Postcode
FROM tblCustomerAddress AS CA 
       LEFT JOIN tblTransactions AS T ON CA.customer_id = T.customer_id
WHERE T.order_status = 'Approved'
GROUP BY CA.[state], CA.[postcode]
ORDER BY Sales_By_Postcode DESC
-- Top 10 postcodes for sales are slightly different than number of customers: most of them are in NSW but 8th is from Victoria and 10th from Queensland


-- Other

-- Job industry
SELECT job_industry_category,
       SUM(list_price) AS Sales_by_Job_Category
FROM tblDemographics AS D 
       LEFT JOIN tblTransactions AS T ON D.customer_id = T.customer_id
WHERE order_status = 'Approved' AND job_industry_category <> 'n/a'
GROUP BY job_industry_category
ORDER BY Sales_by_Job_Category DESC 
-- Top 3 buying job categories are Manufacturing, Financial services, Health

-- Car owning
SELECT owns_car,
       SUM(list_price) AS Sales_by_Car_Owning
FROM tblDemographics AS D 
       LEFT JOIN tblTransactions AS T ON D.customer_id = T.customer_id
WHERE order_status = 'Approved'
GROUP BY owns_car
ORDER BY Sales_by_Car_Owning DESC 
-- No significant difference

-- Repeated purchase 
SELECT past_3_years_purchase_frequency,
       SUM(list_price) AS Sales_by_Past_Purchase_Frequency
FROM tblDemographics AS D 
       LEFT JOIN tblTransactions AS T ON D.customer_id = T.customer_id
WHERE order_status = 'Approved'
GROUP BY past_3_years_purchase_frequency
ORDER BY Sales_by_Past_Purchase_Frequency DESC 
-- No significant difference

-- Wealth
SELECT wealth_segment,
       SUM(list_price) AS Sales_by_Wealth_Segment
FROM tblDemographics AS D 
       LEFT JOIN tblTransactions AS T ON D.customer_id = T.customer_id
WHERE order_status = 'Approved'
GROUP BY wealth_segment
ORDER BY Sales_by_Wealth_Segment DESC 
-- Mass customers are the most buying 



/* Preparng data for copying into Excel and Tableau for visualization */

SELECT * FROM tblCustomerAddress 
SELECT * FROM tblDemographics
SELECT * FROM tblTransactions WHERE order_status = 'Approved'
