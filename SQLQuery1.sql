use Govinda;
use Sales_Performance;

select * from accounts;
select * from products;
select * from sales_pipeline;
select * from sales_teams;

select 'accounts' AS Account, count(*) as row_count
from accounts

Union all

select 'products', count(*) as row_count
from products

Union all

select 'sales_pipeline',count(*) as row_count
from sales_pipeline

Union all

select 'sales_teams',count(*) as row_count
from sales_teams;

/*Check column names and data types*/

select
Table_name,
ordinal_position,
column_name,
data_type,
CHARACTER_MAXIMUM_LENGTH,
is_nullable
from INFORMATION_SCHEMA.COLUMNS
where Table_name in
(
	'accounts',
	'products',
	'sales_pipeline',
	'sales_teams'
)
order by Table_name,ordinal_position;

/*Finding NULL values*/

select	
		count(*) as total_rows,

		sum(case 
			when opportunity_id is NULL
			then 1 else 0 
			end)
		 as null_opportinity_id,
		 
		 sum(case 
			when sales_agent is NULL
			then 1 else 0 
			end)
		 as null_sales_agent,

		 sum(case 
			when product is NULL
			then 1 else 0 
			end)
		 as null_product,

		 sum(case 
			when account is NULL
			then 1 else 0 
			end)
		 as null_account,

		 sum(case 
			when deal_stage is NULL
			then 1 else 0 
			end)
		 as null_deal_stage,

		 sum(case 
			when engage_date is NULL
			then 1 else 0 
			end)
		 as null_engage_date,

		 sum(case 
			when close_date is NULL
			then 1 else 0 
			end)
		 as null_close_date,

		 sum(case 
			when close_value is NULL
			then 1 else 0 
			end)
		 as null_close_value
		 	 
		 FROM sales_pipeline;
		
/* whether the other NULLs are valid or data-quality problems
   Analyse NULL values by deal stage */

select
		deal_stage,
		count(*) as total_opportunities,

		sum(case
				when account is null or LTRIM(RTRIM(account)) = ''
				Then 1 else 0
			end)
			as missing_account, 

			sum(case
				when deal_stage is null 
				Then 1 else 0
			end)
			as missing_deal_stage,

			sum(case
				when engage_date is null 
				Then 1 else 0
			end)
			as missing_engage_date,

			sum(case
				when close_date is null 
				Then 1 else 0
			end)
			as missing_close_date,

			sum(case
				when close_value is null 
				Then 1 else 0
			end)
			as missing_close_value

from sales_pipeline
group by deal_stage
order by deal_stage;

select * from sales_pipeline;
select * from products;

/* Finding duplicate opportunity IDs */

SELECT
    opportunity_id,
    COUNT(*) AS duplicate_count
FROM sales_pipeline
GROUP BY opportunity_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

/* Finding product-name mismatches */

select	
 sp.product as pipeline_product,
 count(*) as affected_rows
 from sales_pipeline as sp
 left join products as p
 on LTRIM(RTRIM(sp.product)) = LTRIM(RTRIM(p.product))
 where p.product is null
 group by sp.product
 order by affected_rows desc;

 /* Now creating a clean copy */

 Select * 
 into sales_pipeline_clean
 from sales_pipeline;

 select 
 (select count(*) from sales_pipeline) as orginal_name,
 (select count(*) from sales_pipeline) as clean_name;

 /* Correcting GTXPro */

BEGIN TRANSACTION;

 update sales_pipeline_clean
 set product = 'GTX Pro'
 where LTRIM(RTRIM(product)) = 'GTXPro'
 select @@ROWCOUNT as updated_rows;

 commit TRANSACTION;

 select
		product,
		count(*) as total_opportunities
	from sales_pipeline_clean
	where product in ('GTXPro', 'GTX Pro')
	group by product;

	select * from sales_pipeline_clean;

/* cleaning account table */

Select *
into accounts_clean
from accounts;

select 
(select count(*) from accounts) as orginal_rows,
(select count(*) from accounts_clean) as clean_rows;

select * from accounts_clean;

select
sector,
COUNT(*) as account_count
from accounts_clean
group by sector
order by sector;

update accounts_clean
set sector = 'technology'
where LTRIM(RTRIM(sector)) = 'technolgy'

select @@ROWCOUNT as corrected_rows;

Select
    office_location,
    COUNT(*) as account_count
from accounts_clean
group by office_location
order by office_location;

update accounts_clean
set office_location = 'Philippines'
where LTRIM(RTRIM(office_location)) = 'Philipines'
select @@ROWCOUNT as corrected_rows;

select * from accounts_clean;

/* checking Duplicate account names*/

select
		LTRIM(RTRIM(account)) as accounts_name,
		count(*) as duplicate_count
		from accounts_clean
		group by LTRIM(RTRIM(account))
		having count(*) > 1; 

/* Find unmatched customer accounts */

select 
		sp.account,
		count(*) as affected_opportunities
		from sales_pipeline_clean as sp
		left join accounts_clean as ac
		on LTRIM(RTRIM(sp.account)) = LTRIM(RTRIM(ac.account))
		where nullif(LTRIM(RTRIM(sp.account)), '') is not null
		and ac.account is null
		group by sp.account;

/* Validate dates and amounts*/

Select
    opportunity_id,
    deal_stage,
    engage_date,
    close_date,
    close_value
from sales_pipeline_clean
where close_date < engage_date
   OR close_value < 0
   OR (
       deal_stage IN ('Won', 'Lost')
       AND (close_date IS NULL OR close_value IS NULL)
   );

/* Check duplicate product and agent keys */

Select product, 
COUNT(*) AS duplicate_count
from products
group by product
having COUNT(*) > 1;

Select sales_agent, 
COUNT(*) AS duplicate_count
From sales_teams
group BY sales_agent
having COUNT(*) > 1;

/* Recheck product matches after cleaning */

Select
    sp.product,
    COUNT(*) AS affected_opportunities
From sales_pipeline_clean AS sp
LEFT JOIN products AS p
    ON LTRIM(RTRIM(sp.product)) = LTRIM(RTRIM(p.product))
where p.product IS NULL
group by sp.product;

/* Check sales-agent matches */

Select
    sp.sales_agent,
    COUNT(*) as affected_opportunities
from sales_pipeline_clean as sp
LEFT JOIN sales_teams as st
    ON LTRIM(RTRIM(sp.sales_agent)) =
       LTRIM(RTRIM(st.sales_agent))
where st.sales_agent IS NULL
group by sp.sales_agent;

/* Now we’ll combine the four tables and validate the result.

Create a reusable reporting view */

Go

create or Alter view dbo.vw_sales_analysis as
select
sp.opportunity_id,
sp.sales_agent,
st.manager,
st.regional_office,
sp.product,
p.series,
p.sales_price,
sp.account,
ac.sector,
ac.office_location,
sp.deal_stage,
sp.engage_date,
sp.close_date,

CAST(sp.close_value as decimal(18,2)) as close_value,
DATEDIFF(Day, sp.engage_date, sp.close_date)
as sales_cycle_days
from sales_pipeline_clean as sp

inner join products as p
on LTRIM(RTRIM(sp.product)) = LTRIM(RTRIM(p.product))

inner join sales_teams as st
on LTRIM(RTRIM(sp.sales_agent)) = LTRIM(RTRIM(st.sales_agent)) 

left join accounts_clean as ac
on LTRIM(RTRIM(sp.account)) = LTRIM(RTRIM(ac.account));
Go

/* checking the view */

select 
		count(*) as joined_rows,
		count(distinct opportunity_id) as unique_opportunities,
		sum
		(case 
				when deal_stage = 'Won'
				then close_value 
				else 0
		end) as won_revenue
from dbo.vw_sales_analysis;		

/* How many opportunities are open, won, or lost */

select 
		deal_stage,
		count(*) as opportuntites,
		CAST(
				100.0 * count(*)/ sum(count(*)) over()  ---- calculates the total across all stage groups --
				as decimal(6,2)
			) as share_of_opportunities_pct
		from dbo.vw_sales_analysis
		group by deal_stage
		order by opportuntites desc;

/* Calculate the closed-deal win rate  */

select
		count(*) as closed_opportunities,

		sum
			(
				case when deal_stage = 'Won'
				then 1
				else 0
			end) as Won_opportunities,


		sum
			(
				case when deal_stage = 'Lost'
				then 1
				else 0
			end) as Lost_opportunities,

		CAST	
			(	
				100.0 * sum
							(
								Case when deal_stage = 'Won'
								then 1 
								else 0
							end) 
				/ nullif(count(*), 0) as decimal(6,2)

				) as win_rate_pct

	from dbo.vw_sales_analysis
	where deal_stage in ('Won', 'Lost');

/* Which products generate the most revenue, and what is their average won deal value? */

select
		product,
		count(*) as won_deals,
		sum(close_value) as won_revenue,
		CAST(AVG(close_value) as decimal(18,2)) as average_won_deal_value
from dbo.vw_sales_analysis
where deal_stage =	'Won'
group by product
order by won_revenue desc;

/* Does a region generate more revenue through more wins or larger deals? */

Select
    regional_office,
    COUNT(*) AS closed_deals,

    SUM(CASE WHEN deal_stage = 'Won'
             THEN 1 ELSE 0 END) AS won_deals,

    CAST(
        100.0 *
        SUM(CASE WHEN deal_stage = 'Won'      /*	West: highest revenue and win rate.
													Central: most won deals, but lowest average deal value.
													East: highest average deal value, despite fewer wins.*/
                 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS win_rate_pct,

    SUM(CASE WHEN deal_stage = 'Won'
             THEN close_value ELSE 0 END) AS won_revenue,

    CAST(
        AVG(CASE WHEN deal_stage = 'Won'
                 THEN close_value END)
        AS DECIMAL(18,2)
    ) AS average_won_deal_value

from dbo.vw_sales_analysis
where deal_stage IN ('Won', 'Lost')
group by regional_office
order by won_revenue DESC;

/* Calculate month-over-month revenue growth */

WITH monthly_revenue AS (
    SELECT
        DATEFROMPARTS(
            YEAR(close_date), MONTH(close_date), 1
        ) AS close_month,
        SUM(close_value) AS won_revenue
    FROM dbo.vw_sales_analysis
    WHERE deal_stage = 'Won'
    GROUP BY
        DATEFROMPARTS(
            YEAR(close_date), MONTH(close_date), 1
        )
),
monthly_comparison AS (
    SELECT
        close_month,
        won_revenue,
        LAG(won_revenue) OVER (
            ORDER BY close_month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    close_month,
    won_revenue,
    previous_month_revenue,
    CAST(
        100.0 * (won_revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0)
        AS DECIMAL(10,2)
    ) AS revenue_growth_pct
FROM monthly_comparison
ORDER BY close_month;

/* How much of the engaging pipeline needs follow-up? */

WITH snapshot AS (
    SELECT MAX(close_date) AS as_of_date
    FROM dbo.vw_sales_analysis
),
aged_pipeline AS (
    SELECT
        v.opportunity_id,
        DATEDIFF(
            DAY, v.engage_date, s.as_of_date
        ) AS age_days
    FROM dbo.vw_sales_analysis AS v
    CROSS JOIN snapshot AS s
    WHERE v.deal_stage = 'Engaging'
)
SELECT
    CASE
        WHEN age_days IS NULL THEN 'Missing engagement date'
        WHEN age_days < 0 THEN 'Future engagement date'
        WHEN age_days <= 30 THEN '0–30 days'
        WHEN age_days <= 60 THEN '31–60 days'
        WHEN age_days <= 90 THEN '61–90 days'
        ELSE 'Over 90 days'
    END AS age_group,
    COUNT(*) AS open_opportunities
FROM aged_pipeline
GROUP BY
    CASE
        WHEN age_days IS NULL THEN 'Missing engagement date'
        WHEN age_days < 0 THEN 'Future engagement date'
        WHEN age_days <= 30 THEN '0–30 days'
        WHEN age_days <= 60 THEN '31–60 days'
        WHEN age_days <= 90 THEN '61–90 days'
        ELSE 'Over 90 days'
    END;

/* Which customers contribute the most won revenue */

WITH account_revenue AS (
    SELECT
        account,
        sector,
        COUNT(*) AS won_deals,
        SUM(close_value) AS won_revenue
    FROM dbo.vw_sales_analysis
    WHERE deal_stage = 'Won'
      AND account IS NOT NULL
    GROUP BY account, sector
),
ranked_accounts AS (
    SELECT
        account,
        sector,
        won_deals,
        won_revenue,

        ROW_NUMBER() OVER (
            ORDER BY won_revenue DESC, account
        ) AS revenue_rank,

        CAST(
            100.0 * won_revenue /
            NULLIF(SUM(won_revenue) OVER (), 0)
            AS DECIMAL(6,2)
        ) AS revenue_share_pct

    FROM account_revenue
)
SELECT *
FROM ranked_accounts
WHERE revenue_rank <= 10
ORDER BY revenue_rank;

/* List older deals for follow-up */

DECLARE @AsOfDate DATE = (
    SELECT MAX(close_date)
    FROM dbo.vw_sales_analysis
);

SELECT
    opportunity_id,
    sales_agent,
    manager,
    regional_office,
    product,
    account,
    engage_date,
    DATEDIFF(DAY, engage_date, @AsOfDate) AS age_days
FROM dbo.vw_sales_analysis
WHERE deal_stage = 'Engaging'
  AND DATEDIFF(DAY, engage_date, @AsOfDate) > 90
ORDER BY age_days DESC, opportunity_id;















