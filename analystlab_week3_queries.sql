-- AnalystLab Africa Week 3 Assignment
-- SQL & Data Querying
-- Intern: Goodness Okoro
-- Datasets: Chinook Database and Sales Dataset

-- Chinook Queries

use chinook;

select count(invoiceId) as total_invoice,
		round(sum(Total), 2) as total_revenue,
        round(avg(Total), 2) as average_invoice_value
from Invoice;
-- Insight:
-- The Chinook store recorded 412 invoices and generated total revenue of $2,328.60.
-- The average invoice value was $5.65, which suggests that most purchases were small-value music transactions.

-- Query 2: Revenue by country
-- This shows which countries generated the highest revenue.
select BillingCountry as country,
		count(InvoiceId) as total_invoices,
        round(sum(Total), 2) as total_revenue
from invoice
group by BillingCountry
having sum(Total) > 100
order by total_revenue Desc; 
-- Insight:
-- The USA generated the highest revenue with $523.06 from 91 invoices.
-- Canada followed with $303.96, while France generated $195.10.
-- This shows that the USA is Chinook's strongest revenue market among countries above $100 revenue.

-- Query 3: Top 10 spending customers
-- This identifies the customers who generated the highest revenue.
select concat(a.FirstName, ' ', a.LastName) as customer_name,
		a.country,
        count(b.InvoiceId) as total_invoices,
        round(sum(b.Total), 2) as total_spent
from Customer as a
inner join Invoice as b
	on a.customerId = b.CustomerId
group by a.CustomerId,
		 customer_name,
         a.Country
order by total_spent Desc 
limit 10;
-- Insight:
-- Helena Holý was the highest-spending customer, with $49.62 across 7 invoices.
-- The top customers had the same number of invoices, but different total spending values.

-- Query 4: Monthly revenue trend
-- This shows how revenue changed across each year and month.
select year(InvoiceDate) as invoice_year,
		month(InvoiceDate) as invoice_month,
        count(InvoiceId) as total_invoices,
        round(sum(Total), 2) as monthly_revenue
from invoice
group by year(InvoiceDate),
		month(InvoiceDate)
order by invoice_year,
	     invoice_month;
--  Highest revenue months
-- This ranks the months from highest revenue to lowest revenue.
select year(InvoiceDate) as invoice_year,
		month(InvoiceDate) as invoice_month,
        count(InvoiceId) as total_invoices,
        round(sum(Total), 2) as monthly_revenue
from invoice
group by year(InvoiceDate),
		month(InvoiceDate)
order by monthly_revenue Desc
limit 10;
-- Insight:
-- Revenue was analyzed by year and month to identify time-based sales patterns.
-- The highest revenue month was 2022-January, with total revenue of $52.62.
-- Other peak months include April 2023, June 2023, and November 2025.
-- This shows that revenue is not equally distributed across all months, so time-based monitoring is useful for spotting sales peaks

-- Query 5: Top music genres by revenue
-- This shows which genres generated the highest revenue.
select c.`Name` as genre,
	   count(d.InvoiceLineId) as total_times_sold,
		round(sum(d.UnitPrice * d.Quantity)) as genre_revenue
from genre as c
inner join track e
	on c.GenreId = e.GenreId
inner join InvoiceLine as d
	on e.TrackId = d.TrackId
group by c.GenreId, 
         c.`Name`
order by genre_revenue Desc
limit 10;
-- Insight:
-- Rock generated the highest genre revenue with $827 from 835 items sold.
-- Latin followed with $382, while Metal generated $261.
-- This shows that Rock is the strongest-performing genre in the Chinook store.

-- Query 6: Sales agent performance
-- This shows which sales support agents generated the highest customer revenue.
select concat(f.FirstName, ' ', f.LastName) as sales_agent,
		f.Title,
        count(distinct a.CustomerId) as total_customers_supported,
        count(b.InvoiceId) as total_invoices,
        round(sum(b.total), 2) as total_revenue
from Employee as f
inner join customer as a
		on f.EmployeeId = a.SupportRepId
inner join invoice as b
	on a.CustomerId = b.CustomerId
group by f.employeeId,
		 sales_agent,
         f.Title
order by total_revenue Desc;
 -- Insight:
-- Jane Peacock generated the highest customer revenue among sales support agents, with $833.04.
-- She supported 21 customers and was linked to 146 invoices.
-- Margaret Park followed with $775.40, while Steve Johnson generated $720.16.
-- This suggests that Jane Peacock had the strongest sales support performance in the Chinook store.   
    
-- Query 7: Rank customers within each country
-- This uses window functions to rank customers based on total spending within their country.
with customer_spending as (
	select a.CustomerId,
		   concat(a.FirstName, ' ', a.LastName) as customer_name,
           a.Country,
           count(b.InvoiceId) as total_invoices,
           round(sum(b.Total), 2) as total_spent
	from Customer as a
    inner join Invoice as b
		on a.CustomerId = b.CustomerId
	group by a.CustomerId,
			 customer_name,
             a.Country
),
ranked_customers AS (
    SELECT 
        customer_name,
        Country,
        total_invoices,
        total_spent,
        RANK() OVER (
            PARTITION BY Country 
            ORDER BY total_spent DESC
        ) AS country_rank,
        ROW_NUMBER() OVER (
            ORDER BY total_spent DESC
        ) AS overall_row_number
    FROM customer_spending
)
SELECT 
    customer_name,
    Country,
    total_invoices,
    total_spent,
    country_rank,
    overall_row_number
FROM ranked_customers
WHERE country_rank = 1
ORDER BY total_spent DESC;
-- Insight:
-- Customers were ranked within each country based on total spending.
-- The query identified the highest-spending customer per country.
-- This demonstrates the use of window functions such as RANK(), ROW_NUMBER(), and PARTITION BY.

 -- Query 8: Customers with spending above the average customer spending
-- This uses a subquery to compare each customer's spending against the average customer spending.
   with customer_totals as (
		select a.CustomerId,
		   concat(a.FirstName, ' ', a.LastName) as customer_name,
           a.Country,
           round(sum(b.Total), 2) as total_spent
	from Customer as a
    inner join Invoice as b
		on a.CustomerId = b.CustomerId
	group by a.CustomerId,
			 customer_name,
             a.Country
)

SELECT 
    customer_name,
    Country,
    total_spent
FROM customer_totals
WHERE total_spent > (
    SELECT AVG(total_spent)
    FROM customer_totals
)
ORDER BY total_spent DESC;
-- Insight:
-- Customers were compared against the average customer spending value.
-- Helena Holý had the highest above-average spending at $49.62.
-- Other above-average customers included Richard Cunningham, Luis Rojas, Ladislav Kovács, and Hugh O'Reilly.
-- This helps identify customers who are more valuable than the average customer.

with customer_totals as (
select a.CustomerId,
		   concat(a.FirstName, ' ', a.LastName) as customer_name,
           a.Country,
           round(sum(b.Total), 2) as total_spent
	from Customer as a
    inner join Invoice as b
		on a.CustomerId = b.CustomerId
	group by a.CustomerId,
			 customer_name,
             a.Country
)

SELECT 
    COUNT(*) AS customers_above_average
FROM customer_totals
WHERE total_spent > (
    SELECT AVG(total_spent)
    FROM customer_totals
);
-- Insight:
-- 22 customers spent above the average customer spending level.
-- This means a smaller group of customers contributed more than the typical customer.
-- These customers can be considered valuable customers for retention or loyalty campaigns.



USE analystlab_week3;

-- Sales Query 1: Overall sales performance
-- This gives a high-level summary of the sales dataset.

select count(*) as total_orders,
	   count(distinct ORDERNUMBER) as total_orders,
       round(sum(SALES), 2) as total_sales,
       round(avg(SALES), 2) as average_sales_per_line,
       min(ORDERDATE_CLEAN) as first_order_date,
       max(ORDERDATE_CLEAN) as last_order_date
from sales_clean;



