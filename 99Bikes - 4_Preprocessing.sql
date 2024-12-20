USE Portfolio_Sales_99Bikes
GO

/* CUSTOMER ADDRESS TABLE */

SELECT * 
FROM [dbo].[tblCustomerAddress]
WHERE [customer_id] IS NULL 
    OR [address] IS NULL 
    OR [postcode] IS NULL
    OR [state] IS NULL
    OR [country] IS NULL
    OR [property_valuation] IS NULL
-- no missing values on any column

-- Do we have address data for all customers in the demographics table?
SELECT *
FROM tblDemographics AS D 
       FULL OUTER JOIN tblCustomerAddress AS CA ON D.customer_id = CA.customer_id
WHERE CA.customer_id IS NULL 
    OR D.customer_id IS NULL 
-- We have
--3 customers for which we have geographical data but not demographical --> this data is gonna be ignored ion further analysis by not including it in join tables
--4 customers for which we have demographical data but not geographical --> this data is gonna be fixed by setting 'Unknown' in string fields and average or mode in number fields 
begin tran

DECLARE @mode_postcode smallint 
SELECT @mode_postcode = (SELECT TOP 1 postcode FROM [dbo].[tblCustomerAddress] GROUP BY postcode ORDER BY COUNT(*))

DECLARE @mode_property_val tinyint 
SELECT @mode_property_val = (SELECT TOP 1 property_valuation FROM [dbo].[tblCustomerAddress] GROUP BY property_valuation ORDER BY COUNT(*))

INSERT INTO [dbo].[tblCustomerAddress] ([customer_id],[address],[postcode],[state],[country],[property_valuation])
VALUES 
(3, 'Unknown', @mode_postcode, 'Unknown', 'Australia', @mode_property_val),
(10, 'Unknown', @mode_postcode, 'Unknown', 'Australia', @mode_property_val),
(22, 'Unknown', @mode_postcode, 'Unknown', 'Australia', @mode_property_val),
(23, 'Unknown', @mode_postcode, 'Unknown', 'Australia', @mode_property_val)

SELECT * FROM tblDemographics AS D LEFT JOIN tblCustomerAddress AS CA ON D.customer_id = CA.customer_id WHERE CA.customer_id IS NULL 
commit tran 
-- No more missing geographical data for recorded customers



/** DEMOGRAPHICS TABLE */

SELECT *
FROM [dbo].[tblDemographics]
WHERE [customer_id] IS NULL
-- no missing values

SELECT *
FROM [dbo].[tblDemographics]
WHERE [first_name] IS NULL 
-- no missing values

SELECT *
FROM [dbo].[tblDemographics]
WHERE [last_name] IS NULL
-- 125 missing values --> not necessary for analysis --> no action

SELECT *
FROM [dbo].[tblDemographics]
WHERE [gender] IS NULL
-- no missing values

SELECT *
FROM [dbo].[tblDemographics]
WHERE [past_3_years_bike_related_purchases] IS NULL
-- no missing values

-- Clustering into 3 categories for easier analysis
--1. Defining min and max values
SELECT MIN(past_3_years_bike_related_purchases), MAX(past_3_years_bike_related_purchases)
FROM tblDemographics
--2. Defining the categories
SELECT past_3_years_bike_related_purchases,
       CASE 
              WHEN past_3_years_bike_related_purchases BETWEEN 0 AND 33 THEN 'Low (0 - 33)'
              WHEN past_3_years_bike_related_purchases BETWEEN 34 AND 66 THEN 'Moderate (34 - 66)'
              ELSE 'High (67 - 99)'
       END
FROM tblDemographics
--3. Creating the new column
ALTER TABLE [dbo].[tblDemographics] 
ADD past_3_years_purchase_frequency varchar(50)
GO
--4. Setting the values
UPDATE [dbo].[tblDemographics]
SET [past_3_years_purchase_frequency] = 
    CASE 
        WHEN past_3_years_bike_related_purchases BETWEEN 0 AND 33 THEN 'Low (0 - 33)'
        WHEN past_3_years_bike_related_purchases BETWEEN 34 AND 66 THEN 'Moderate (34 - 66)'
        ELSE 'High (67 - 99)'
    END
FROM tblDemographics

SELECT *
FROM [dbo].[tblDemographics]
WHERE [date_of_birth] IS NULL 
-- 87 missing values --> this column is used for calculating age --> missing values will be fixed for age 

-- Creating age at purchase column
--1. Checking if we have multiple years for the transactions data
SELECT DISTINCT(YEAR(transaction_date))
FROM tblTransactions
-- all transaction data is from 2017
--2. Creating the new column
ALTER TABLE tblDemographics 
ADD age_at_purchase int 
GO
--3. Setting the values for age
UPDATE tblDemographics 
SET age_at_purchase = DATEDIFF(YEAR, date_of_birth, '2017-12-31')
GO
--4. Checking that it worked correctly
SELECT customer_id
       , date_of_birth
       , age_at_purchase
       , DATEDIFF(YEAR, date_of_birth, '2017-12-31') AS age_at_purchase_calc
       , age_at_purchase - DATEDIFF(YEAR, date_of_birth, '2017-12-31') AS age_diff
FROM tblDemographics
ORDER BY age_diff DESC
--5. Checking for missing values
SELECT *
FROM [dbo].[tblDemographics]
WHERE [age_at_purchase] IS NULL 
-- 87 missing values --> we decide to create a new age_group where age is set as 'unknown' when missing

-- Creating the new age_group column
--1. Checking min and max value
SELECT MIN(age_at_purchase) AS MinAge, MAX(age_at_purchase) AS MaxAge
FROM tblDemographics
--2. Adding the new column
ALTER TABLE [dbo].[tblDemographics] 
ADD age_group varchar(50)
GO
--3. Setting 10yrs wide age bins, related to different purchasing power
UPDATE [dbo].[tblDemographics] 
SET age_group =
    CASE
        WHEN age_at_purchase <= 24 THEN 'Young Adults (< 25)'
        WHEN age_at_purchase > 24 AND age_at_purchase <= 34 THEN 'Young Professionals (25 - 34)'
        WHEN age_at_purchase >34 AND age_at_purchase <= 44 THEN 'Established Professionals (35 - 44)'
        WHEN age_at_purchase > 44 AND age_at_purchase <= 54 THEN 'Mature Professionals (45 - 54)'
        WHEN age_at_purchase > 54 AND age_at_purchase <= 64 THEN 'Pre-Retirees (55 - 64)'
        WHEN age_at_purchase > 64 AND age_at_purchase <= 74 THEN 'Young Seniors (65 - 74)'
        WHEN age_at_purchase > 74 THEN 'Older Seniors (75 +)'
        ELSE 'Unknown'
    END 
FROM tblDemographics
--4. Checking for missing values
SELECT * 
FROM [dbo].[tblDemographics]
WHERE [age_group] IS NULL
-- no missing values

SELECT *
FROM [dbo].[tblDemographics]
WHERE [job_title] IS NULL 
-- 506 missing values --> this column is clustered in the industry_category --> only that column will be used  --> no action

SELECT *
FROM [dbo].[tblDemographics]
WHERE [job_industry_category] IS NULL
-- no missing values

SELECT *
FROM [dbo].[tblDemographics]
WHERE [wealth_segment] IS NULL
-- no missing values

SELECT *
FROM [dbo].[tblDemographics]
WHERE [owns_car] IS NULL
-- no missing values

SELECT *
FROM [dbo].[tblDemographics]
WHERE [tenure] IS NULL
-- no missing values



/* TRANSACTIONS TABLE */

SELECT * 
FROM [dbo].[tblTransactions]
WHERE [transaction_id] IS NULL 
    OR [product_id] IS NULL
    OR [customer_id] IS NULL
    OR [transaction_date] IS NULL 
    OR [online_order] IS NULL
    OR [order_status] IS NULL
    OR [brand] IS NULL
    OR [product_line] IS NULL
    OR [product_class] IS NULL
    OR [product_size] IS NULL
    OR [list_price] IS NULL
    OR [standard_cost] IS NULL
    OR [product_first_sold_date] IS NULL 

SELECT * 
FROM [dbo].[tblTransactions]
WHERE [transaction_id] IS NULL 
-- no missing values

SELECT * 
FROM [dbo].[tblTransactions]
WHERE [product_id] IS NULL
-- no missing values

SELECT * 
FROM [dbo].[tblTransactions]
WHERE [transaction_date] IS NULL
-- no missing values

SELECT * 
FROM [dbo].[tblTransactions]
WHERE [online_order] IS NULL
-- 360 missing values 
UPDATE [dbo].[tblTransactions]
SET [online_order] = 'UNKNOWN' WHERE [online_order] IS NULL 
-- missing values have been replaced with 'UNKNOWN'

SELECT * 
FROM [dbo].[tblTransactions]
WHERE [order_status] IS NULL 
-- no missing values

SELECT * 
FROM [dbo].[tblTransactions]
WHERE [brand] IS NULL 
-- 197 missing values
UPDATE [dbo].[tblTransactions] 
SET [brand] = 'Unknown'
WHERE [brand] IS NULL 


SELECT * 
FROM [dbo].[tblTransactions]
WHERE [product_line] IS NULL 
-- 197 missing values
UPDATE [dbo].[tblTransactions] 
SET [product_line] = 'Unknown'
WHERE [product_line] IS NULL 

SELECT * 
FROM [dbo].[tblTransactions]
WHERE [product_class] IS NULL 
-- 197 missing values
UPDATE [dbo].[tblTransactions] 
SET [product_class] = 'Unknown'
WHERE [product_class] IS NULL 

SELECT * 
FROM [dbo].[tblTransactions]
WHERE [product_size] IS NULL
-- 197 missing values
UPDATE [dbo].[tblTransactions] 
SET [product_size] = 'Unknown'
WHERE [product_size] IS NULL 

SELECT * 
FROM [dbo].[tblTransactions]
WHERE [standard_cost] IS NULL 
-- 197 missing values --> it can't be replaced by 'Unknown' because it's not a string 

-- Checking for proportion of missing data compared to total data
GO
DECLARE @CountNull float 
SELECT @CountNull = COUNT(*) FROM tblTransactions WHERE standard_cost IS NULL 
DECLARE @CountTotal int 
SELECT @CountTotal = COUNT(*) FROM tblTransactions
SELECT @CountNull * 100 / @CountTotal AS PercentageMissingCost
GO
-- Missing data is < 1%

-- Replacing missing standard_cost values by average value 
begin tran 
DECLARE @AvgCost smallmoney 
SELECT @AvgCost = AVG(standard_cost) FROM tblTransactions WHERE standard_cost IS NOT NULL 
UPDATE [dbo].[tblTransactions]
SET [standard_cost] = ISNULL(standard_cost, @AvgCost)

SELECT * FROM [dbo].[tblTransactions] WHERE [standard_cost] IS NULL 
commit tran
-- no more missing values for standard_cost

SELECT * 
FROM [dbo].[tblTransactions]
WHERE [list_price] IS NULL 
-- no missing values

SELECT *
FROM [dbo].[tblTransactions]
WHERE [product_first_sold_date] IS NULL 
-- 197 missing values, can't be replaced with 'Unknown' 

-- We decide to create a new column to group the first_sold_date and set missing values as 'Unknown'
--1. Evaluating min and max
SELECT 
    MIN(product_first_sold_date) AS MinFirstSoldDate, 
    MAX(product_first_sold_date) AS MaxFirstSoldDate
FROM tblTransactions
--2. Creating the new column
ALTER TABLE [dbo].[tblTransactions]
ADD product_first_sold_period varchar(50)
GO
--3. Setting 5 years wide date bins
UPDATE tblTransactions
SET product_first_sold_period = 
CASE 
    WHEN product_first_sold_date <= '1995-12-31' THEN 'Early 1990s'
    WHEN product_first_sold_date > '1995-12-31' AND product_first_sold_date <= '2000-12-31' THEN 'Late 1990s'
    WHEN product_first_sold_date > '2000-12-31'  AND product_first_sold_date <= '2005-12-31' THEN 'Early 2000s'
    WHEN product_first_sold_date > '2005-12-31' AND product_first_sold_date <= '2010-12-31' THEN 'Late 200s'
    WHEN product_first_sold_date > '2010-12-31' THEN 'Recent Years'
    ELSE 'Unknown'
END
FROM tblTransactions
--4. Checking for missing values
SELECT * 
FROM [dbo].[tblTransactions]
WHERE product_first_sold_period IS NULL 
-- no missing values

-- We decide to also create a product_longevity column to facilitate calculations
ALTER TABLE [dbo].[tblTransactions]
ADD product_longevity int
GO

UPDATE [dbo].[tblTransactions]
SET [product_longevity] = DATEDIFF(year, product_first_sold_date, '2017-12-31')
