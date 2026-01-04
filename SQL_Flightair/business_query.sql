/* 
total revenue for flightair
*/

select sum(ticket_price) as total_revenue

from
  core.tickets;

/*
How many tickets have been sold in total?
*/

select count (distinct ticket_id) as total_tickets_sold

from
  core.tickets;

/*
What is the average ticket price across all flights?
*/

select 
  round(avg(ticket_price),2) as average_ticket_price

from
  core.tickets;

/*
Which routes generate the highest total revenue?
*/

select 
  route_code,
  sum(ticket_price) as revenue_per_route

from
  core.tickets

inner join
  core.flights on tickets.flight_id = flights.flight_id

inner join 
  core.routes on flights.route_id = routes.route_id

group by route_code

order by revenue_per_route desc 

limit 5;

/*
Which routes have the highest passenger volume?
*/


select 
  route_code,
  count(ticket_id) as passenger_volume

from 
  core.tickets

inner join
  core.flights on tickets.flight_id = flights.flight_id

inner join 
  core.routes on flights.route_id = routes.route_id

group by route_code

order by passenger_volume desc

limit 5;

/*
What is the total revenue generated 
between Arlanda (ARN) and London (LHR)?
*/


select 
  sum(ticket_price) as "Total revenue for ARN-LHR"

from
  core.tickets

inner join 
  core.flights on tickets.flight_id = flights.flight_id

inner join 
  core.routes on flights.route_id = routes.route_id

where route_code in ('ARN-LHR', 'LHR-ARN');


/*
Who are the top 10 customers by total spend?
*/

select
  tickets.customer_id,
  first_name,
  last_name,
  
  sum(tickets.ticket_price) as total_spent

from
  core.customers

inner join 
  core.tickets on customers.customer_id = tickets.customer_id

group by
  first_name,
  last_name,
  tickets.customer_id

order by total_spent desc 

limit 10;

/*
How is revenue distributed across age groups (Kids, Adults, Pensioners)?
*/

select

  case 
  when date_diff('year', date_of_birth, current_date) < 18 then 'Kids'
  when date_diff('year', date_of_birth, current_date) < 65 then 'Adults'
  else 'Pensioners' 
end as age_group,

sum(ticket_price) as total_revenue

from 
  core.customers

inner join 
  core.tickets on customers.customer_id = tickets.customer_id

group by age_group

order by age_group;


/*
 How does travel class usage differ between age groups?
 */

select
  case 
    when date_diff('year', date_of_birth, current_date) < 18 then 'Kids'
    when date_diff('year', date_of_birth, current_date) < 65 then 'Adults'
    else 'Pensioners' 
  end as age_group,

  travel_class,

  count(*) as travel_count
 
from core.customers

inner join 
  core.tickets on  customers.customer_id = tickets.customer_id

group by age_group, travel_class

order by age_group;

/*
What is the total revenue per travel class?
*/

select
  travel_class,
  sum(ticket_price) as total_revenue

from core.tickets

group by travel_class

order by total_revenue desc ;


/*
What is the average ticket price per travel class?
*/

select 
  travel_class,
  round(avg(ticket_price),2 )as average_ticket_price

from
  core.tickets

group by travel_class ;


/*
Which travel class contributes the most to total revenue?
*/

select
  travel_class,
  sum(ticket_price) as total_revenue

from
  core.tickets
group by travel_class
order by total_revenue desc 
limit 1;


/*
 How many flights are operated per month?
*/

select 
  
  strftime('%Y-%m', flight_date) as month,
  count(*) as Flights_operated

from 
  core.flights
group by month
order by month;


/*
How does monthly revenue trend over time?
*/

select 
  strftime('%Y-%m', flight_date) as month,
  sum(ticket_price) as monthly_revenue

from
  core.flights

inner join 
  core.tickets on tickets.flight_id = flights.flight_id

group by month 
order by month;


/*
Which month generates the highest total revenue?
*/

select 
  strftime('%Y-%m', flight_date) as month,
  sum(ticket_price) as monthly_revenue

from core.flights

inner join 
  core.tickets on flights.flight_id = tickets.flight_id

group by 
  month 
order by monthly_revenue desc 

limit 1;

/* 
What percentage of total ticket revenue in Q1 comes from Business class?
*/

/* 
What percentage of total ticket revenue in Q1 comes from Business class?
*/

with revenue_Q1 as 
(
select 
  sum(ticket_price) as tot_revenue_Q1,
  sum(ticket_price) filter (where travel_class = 'Business') as business_rev,
  sum(ticket_price) filter (where travel_class = 'Economy') as economy_rev
    
from 
  core.tickets
)

select
  round (business_rev / tot_revenue_Q1 * 100, 2 )as "Business_rev in %",

from 
  revenue_Q1;


/*
my stakeholders want full name and email of all passengers that traveled between London and copenhagen during Mars.
*/

select

  concat(first_name, ' ', last_name) as "Customers",
  email as Email

from
  core.customers

inner join 
  core.tickets on customers.customer_id = tickets.customer_id

inner join 
  core.flights on tickets.flight_id = flights.flight_id

inner join 
  core.routes on flights.route_id = routes.route_id

where flight_date between '2025-03-01' and '2025-03-31'
and route_code = 'LHR-CPH'

/*
Devide customers into following category, Kids (0-17), Adults(18-64), Pensioners(65+)
*/

select

  case 
    when date_diff('year', date_of_birth, current_date) < 18 then 'Kids'
    when date_diff('year', date_of_birth, current_date) < 65 then 'Adults'
    else 'Pensioners'
  end as age_group,

  count(*) as 'count'

from 
  core.customers

 group by age_group


/* 
Stakeholders want a view to analyse flights betweeen Arlanda och London
*/ 

create view core.london_arlanda as 
(

select
  customers.customer_id,
  routes.route_code,
  first_name,
  last_name,
  email,
  ticket_price,
  travel_class,
  flight_date,
  gender,
  date_of_birth
  
from 
  core.customers

    inner join
      core.tickets on tickets.customer_id = customers.customer_id

    inner join 
      core.flights on tickets.flight_id = flights.flight_id

    inner join 
      core.routes on routes.route_id = flights.route_id

    where  route_code in ('ARN-LHR', 'LHR-ARN')
  
)