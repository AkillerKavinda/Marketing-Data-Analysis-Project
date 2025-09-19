use Marketing;

-- Having a look at the tables in the database

select * from customer_journey;

select * from customer_reviews;

select * from customers;

select * from engagement_data;

select* from geography;

select * from products;

-- Categorize the products based on their price 

select * from products;

select ProductId, ProductName, Price,
case
	when price <= 50 then 'Low'
	when price <= 200 then 'Medium'
	else 'High'
end as price_category
from products;

-- Join the customers table with the geography table to enrich customer data with geography information

select * from customers;
select * from geography;

select c.CustomerId, c.Customername, c.Email, c.Gender, c.Age, g.Country, g.City
from customers c
join geography g
on c.geographyId = g.GeographyID;

-- Clean whitespace issues in the ReviewText column

select * from customer_reviews;

select ReviewID, CustomerID, ProductID, ReviewDate, Rating, trim(reviewText) as Reviews
from customer_reviews;

select reviewid, customerid, productid, reviewdate, Rating, replace(reviewText, '  ', ' ') as Reviews
from customer_reviews;

-- Clean and normalize the engagement_data table

select * from engagement_data;

select EngagementID, ContentID, CampaignID, ProductID, 
upper(replace(contenttype, 'Socialmedia', 'Social Media')) as ContentType, ViewsClicksCombined,
left(ContentID, charindex('-', ViewsClicksCombined) - 1) as Views,
right(ViewsClicksCombined, len(ViewsClicksCombined) - charindex('-', ViewsClicksCombined)) as Clicks, 
Likes, 
format(convert(date, EngagementDate), 'dd.MM.yyyy') as EngagementDate
from engagement_data
where ContentType != 'Newsletter';

-- Write a Common Table Expression (CTE) to identify and tag duplicate records


with cte as (select *,
row_number() over(partition by engagementId, ContentId, CampaignID, ProductID, ContentType, ViewsClicksCombined order by engagementId) as rk
from engagement_data)

select * from cte 
where rk >1

select * from customer_journey;

with cte as (
	select JourneyId, CustomerId, ProductId, VisitDate, Stage, Action, Duration,
	row_number() over(partition by JourneyId, CustomerID, ProductID, VisitDate, Stage, Action order by JourneyID) as rk
	from customer_journey)

select * from cte 
where rk > 1
;

-- Selecting the final cleaned and standardized data

select JourneyId, CustomerId, ProductID, VisitDate, Stage, Action, coalesce(duration, avg_duration) as duration
from (
	select 
		JourneyID, 
		CustomerID, 
		ProductID, 
		VisitDate, 
		upper(Stage) as stage, 
		Action, 
		Duration, 
		avg(Duration) over (partition by visitDate) as avg_duration, 
		row_number() over (partition by customerId, ProductId, VisitDate, upper(Stage), action order by JourneyId) as row_num
	from customer_journey
	) as subquery
where row_num = 1;