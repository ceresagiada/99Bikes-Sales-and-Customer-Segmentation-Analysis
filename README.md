# 99Bikes Sales & Customer Demographics Analysis

Personal portfolio project analysing sales performance and customer demographics for a real Australian bicycle retailer, using a publicly available dataset from @Kaggle.

---

## Project Overview

The primary objective of this project is to clean and analyse a multi-table sales dataset to surface key business indicators and understand what customer characteristics and contextual factors influence purchasing behaviour.

- **Objective 1**: Analyse overall sales and profit performance across products, brands, and time.
- **Objective 2**: Identify customer segments (by age, gender, geography, occupation) that drive the most sales, and understand whether these factors influence purchasing patterns differently across groups.

---

## Workflow Architecture

### 1. The Dataset

99Bikes Sales Data ([Kaggle](https://www.kaggle.com/datasets/tforsyth/99bikes-sales-data)), consisting of 4 relational tables used for this analysis.

| Table | Description | Rows |
|---|---|---|
| `Transactions` | Order-level sales data with product and pricing info | ~20,000 |
| `CustomerDemographic` | Customer profile data (age, gender, job, wealth segment) | ~4,000 |
| `CustomerAddress` | Customer location data (address, postcode, state) | ~4,000 |
| `NewCustomerList` | Prospective new customers with demographic and address info | ~1,000 |

---

### 2. Data Cleaning & Preprocessing

Initial cleaning was performed in **Excel**, followed by deeper preprocessing and feature engineering in **SQL Server**.

#### Excel (Initial Cleaning)
- Checked for duplicate rows.
- Removed unnecessary columns.
- Standardised formatting (case, spacing).
- Validated categorical fields and data types (currencies, dates).

#### SQL Server (Preprocessing)

**Customer Address Table**
- No missing values found in any column.
- Cross-join check against Demographics revealed 3 customers with address data but no demographic record (excluded from analysis) and 4 customers with demographic data but no address. The 4 missing address records were imputed: string fields set to `'Unknown'`, postcode and property valuation set to their respective **mode** values.

**Demographics Table**
- `last_name`: 125 missing values — not needed for analysis, no action taken.
- `job_title`: 506 missing values — superseded by `job_industry_category`, no action taken.
- `past_3_years_bike_related_purchases`: Clustered into 3 frequency bands — *Low (0–33)*, *Moderate (34–66)*, *High (67–99)* — stored in new column `past_3_years_purchase_frequency`.
- `date_of_birth`: 87 missing values — used to derive `age_at_purchase` (calculated as of 31 Dec 2017, the last transaction year). Missing ages were handled by creating an `age_group` column with 10-year bins (*Young Adults*, *Young Professionals*, *Established Professionals*, *Mature Professionals*, *Pre-Retirees*, *Young Seniors*, *Older Seniors*) and an *Unknown* bucket for missing values.

**Transactions Table**
- `online_order`: 360 missing values → replaced with `'UNKNOWN'`.
- `brand`, `product_line`, `product_class`, `product_size`: 197 missing values each (same records) → replaced with `'Unknown'`.
- `standard_cost`: 197 missing values (<1% of total) → replaced with the **average cost** of non-null records.
- `product_first_sold_date`: 197 missing values — cannot be replaced with a string, so a new `product_first_sold_period` column was created with 5-year era bins (*Early 1990s*, *Late 1990s*, *Early 2000s*, *Late 2000s*, *Recent Years*, *Unknown*). A companion `product_longevity` column (years since first sold, as of 2017) was also added.
- Two additional customer-level aggregate columns were computed and stored in the Transactions table for use in Tableau: `customer_transaction_count` and `customer_transaction_avg_amount`.

[View the Preprocessing Script](99Bikes%20-%204_Preprocessing.sql)

---

### 3. Exploratory Analysis

Exploratory analysis was performed in **SQL Server**, filtering all results to `order_status = 'Approved'` orders only.

**Sales & Profit Summary**
- Calculated total sales and total profit across all approved transactions.
- No meaningful difference found between online and in-store sales.
- Top 3 selling products: IDs 3, 0, 38. Top 3 by profit: IDs 3, 38, 57.
- Top selling brands: Solex, WeareA2B, Giant Bicycles. Top profitable brands: WeareA2B, Solex, Trek Bicycles.
- Medium class and medium size products are both the top sellers and most profitable across their respective dimensions.

**Trend Analysis**
- Top selling months: October, August, May (differences are small).
- Seasonal split shows Summer as the top-selling season, though all four seasons are relatively close in volume.

**Customer Segmentation**
- Gender: roughly equal split, no significant sales difference.
- Age: *Established Professionals (35–44)* generate the most total sales — primarily because they are the largest customer group (nearly twice the size of the second-largest group). Per-customer transaction frequency is actually highest among *Young Seniors (65–74)*, who also spend the most per transaction on average.
- Geography: All customers are from Australia across 3 states. New South Wales accounts for approximately twice as many customers and the highest sales of any state. Top postcodes by customer count and by sales are predominantly in NSW, with a few entries from Victoria and Queensland.
- Job industry: Manufacturing, Financial Services, and Health are the top 3 buying job categories.
- Car ownership and past purchase frequency show no significant impact on sales volume.
- Wealth segment: Mass Customers represent the largest buying group.

[View the Exploratory Analysis Script](99Bikes%20-%205_ExploratoryAnalysis.sql)

---

### 4. The Dashboard

Data was exported from SQL Server into Excel (one sheet per table) and connected to **Tableau** via a join sequence: `CustomerAddress` → right join → `CustomerDemographic` → left join → `Transactions`.

Two Tableau dashboards were built:

**99Bikes Sales Performance for 2017**
- Total Sales & Profit (KPI cards)
- Monthly Sales & Profit trend
- Transaction Count & Sales by Top-Selling Brand
- Sales by Product Class
- Sales by Product Size
- Sales by Product Longevity

**99Bikes Customer Sales & Demographics Overview for 2017**
- Key Customer Statistics
- Sales by Age & Gender
- Sales by Job Industry
- Sales by State (map)
- Sales by Postcode

[View the Dashboard through Tableau](99Bikes%20-%205_ExploratoryAnalysis.sql)
[View the Dashboard online](https://public.tableau.com/views/99Bikes-SalesCustomerSegmentationAnalysis/CustomersDashboard?:language=en-GB&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

---

## Results & Business Impact

- **Delivery channel is not a differentiator**: online and in-store sales are nearly identical, suggesting the business should not prioritise one over the other.
- **Product focus**: Medium class and medium size bikes dominate both sales and profit. WeareA2B is the most profitable brand despite Solex leading on raw sales volume.
- **Core customer profile**: The highest-value customers per transaction are *Young Seniors (65–74)*, while *Established Professionals (35–44)* dominate in total volume due to sheer group size. Both segments are worth targeting with different strategies.
- **Geographic concentration**: New South Wales is the dominant market. Expansion or marketing investment in Victoria and Queensland could yield growth opportunities.
- **Wealth and prior purchase history are not strong sales predictors**: Mass Customers are the biggest buyers, and past purchase frequency shows little differentiation — suggesting that acquisition of new customers matters as much as retention.

---

## Tech Stack

| Tool | Usage |
|---|---|
| **Excel** | Initial data cleaning, formatting validation, and data export for SQL import and Tableau |
| **SQL Server (T-SQL)** | Data preprocessing, feature engineering, and exploratory analysis |
| **Tableau** | Interactive dashboard and data visualization |
