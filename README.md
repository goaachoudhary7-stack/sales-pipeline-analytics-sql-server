# Sales Pipeline Analytics | SQL Server

Turning sales opportunity data into trustworthy reporting and actionable commercial insights.

## Business Problem

Sales leaders need to understand which products and regions drive revenue, how effectively opportunities convert, and where further investigation is needed.

This project combines four sales datasets in SQL Server, resolves data-quality issues, validates reporting totals, and analyses revenue, conversion, and deal value.

## Project Overview

| Dataset        | Records | Purpose                                          |
| -------------- | ------: | ------------------------------------------------ |
| Sales Pipeline |   8,800 | Opportunities, stages, dates, and closing values |
| Accounts       |      85 | Customer sectors and locations                   |
| Products       |       7 | Product series and reference prices              |
| Sales Teams    |      35 | Agents, managers, and regional offices           |

**Tools:** SQL Server, SQL Server Management Studio
**Reporting grain:** One row per opportunity

## Key Results

* Corrected **1,480 product-name mismatches**, standardizing `GTXPro` to `GTX Pro`.
* Corrected account-sector and country spelling inconsistencies.
* Preserved original imported data and applied corrections to separate clean tables.
* Validated **8,800 rows and 8,800 unique opportunities** after joining all four datasets.
* Reconciled total won revenue to **10,005,534.00**.
* Identified **4,238 won, 2,473 lost, and 2,089 open opportunities**.
* Calculated a **63.15% closed-deal win rate**: Won ÷ (Won + Lost).

## Business Findings

### 1. Deal volume does not equal revenue contribution

GTX Basic recorded the most won deals—**915**—but generated **499,263.00** in revenue.

GTX Pro generated **3,510,578.00** from **729** won deals, reflecting a substantially higher average deal value.

**Recommendation:** Investigate suitable upsell opportunities and product mix. Revenue alone does not justify deprioritizing lower-priced products; profitability and customer needs must also be considered.

### 2. Central’s revenue gap warrants a product-mix investigation

| Region  | Won Deals | Win Rate |  Won Revenue | Average Won Deal Value |
| ------- | --------: | -------: | -----------: | ---------------------: |
| West    |     1,438 |   63.94% | 3,568,647.00 |               2,481.67 |
| Central |     1,629 |   62.56% | 3,346,293.00 |               2,054.20 |
| East    |     1,171 |   63.02% | 3,090,594.00 |               2,639.28 |

Central won the most deals but had the lowest average won deal value.

**Recommendation:** Compare product and customer mix before attributing the difference to sales-agent performance.

### 3. High-value products require sample-size awareness

GTK 500 had an average won deal value of **26,707.47**, but only **15 won deals**.

**Recommendation:** Investigate its growth potential without assuming a small sample predicts future performance.

## Data Quality and Validation

The workflow included:

* Row-count reconciliation against all four source files.
* Duplicate opportunity and lookup-key checks.
* NULL profiling by deal stage.
* Product, account, and sales-agent match validation.
* Checks for negative closing values and closing dates before engagement.
* Joined-row and revenue reconciliation.

Open opportunities retained NULL closing dates and values. These represent deals without a final outcome—not values to replace with zero or fabricated dates.

A `LEFT JOIN` preserved opportunities without assigned accounts. Product and agent relationships used `INNER JOIN` after match validation.

## SQL Skills Demonstrated

* Aggregations with `GROUP BY` and `HAVING`
* Conditional calculations using `CASE`
* `INNER JOIN` and `LEFT JOIN`
* Text standardization with `LTRIM` and `RTRIM`
* Reporting views and decimal casting
* Date calculations with `DATEDIFF`
* Safe updates using transactions
* Percentage calculations with decimal division and `NULLIF`

## How to Reproduce

1. Import the four CSV files into SQL Server.
2. Profile row counts, data types, duplicates, and NULLs.
3. Create clean copies and standardize inconsistent values.
4. Validate lookup keys and business rules.
5. Create `dbo.vw_sales_analysis` to combine the datasets.
6. Reconcile opportunity counts and won revenue.
7. Run the product and regional analysis queries.

## Limitations

* Revenue is measured using the closing values of Won opportunities; it is not profit.
* Currency and source provenance should be documented from the dataset’s original documentation.
* The data does not include costs, loss reasons, sales targets, or lead-quality measures.
* Recommendations are analytical proposals, not implemented or measured business outcomes.
* This project treats the supplied data as a historical snapshot, not a live pipeline.

## Author

**Govinda Choudhary**
Reporting and Marketing Analytics | SQL | Power BI

[LinkedIn](https://www.linkedin.com/in/govindachoudhary/)
