Create Database Pizza;
use pizza;

-- 1 : Retrieve the total number of orders placed.

select count(order_id) as total_orders from orders;


-- 2 : Calculate the total revenue generated from pizza sales.

select sum(od.quantity*p.price) as Revenue from order_details od
join pizzas p
on od.pizza_id=p.pizza_id ;
-- or we can get same result with below query also. 
select sum(od.quantity*p.price) as Revenue from order_details od
join pizzas p
using (pizza_id);

-- 3 : Identify the highest price pizza

select p.price, pt.name, p.size from pizza_types pt
join pizzas p
on pt.pizza_type_id=p.pizza_type_id
order by p.price desc 
limit 1;

-- 4 : Identify the most common pizza size ordered.

select sum(od.quantity) as Total_pizza_ordered, p.size from order_details od
join pizzas p 
on od.pizza_id=p.pizza_id
group by p.size
order by sum(od.quantity) desc
limit 1;


-- 5 : List the top 5 most ordered pizza types along with their quantities.

select sum(order_details.quantity) as quantity, pizza_types.name from order_details
join pizzas
on order_details.pizza_id = pizzas.pizza_id
join pizza_types
on pizzas.pizza_type_id = pizza_types.pizza_type_id
group by pizza_types.name
order by sum(order_details.quantity)
desc limit 5;	

-- 6 : Join the necessary tables to find the total quantity of each pizza category ordered.

select sum(order_details.quantity), pizza_types.category from order_details 
join pizzas
on order_details.pizza_id = pizzas.pizza_id
join pizza_types
on pizzas.pizza_type_id = pizza_types.pizza_type_id
group by pizza_types.category
order by sum(order_details.quantity)
desc;

-- 7 : Determine the distribution of orders by hour of the day.

select hour(time), count(order_id) from orders
group by hour(time)
order by count(order_id);  

-- 8 :Find the category wise distribution of pizzas. 

select count(name), category from pizza_types
group by category;

-- 9 : Group the orders by date and calculate the average number of pizzas ordered per day. 

With order_quantity as (
select orders.date, sum(order_details.quantity) as total_quantity from order_details
join orders
on order_details.order_id = orders.order_id
group by orders.date
)
select round(avg(total_quantity),0) as AVG_PIZZA_Ordered_PER_DAY from order_quantity; 

-- 10 : Determine the top 3 most ordered pizza types based on revenue.

select pt.name, sum(od.quantity*p.price) as revenue from pizza_types pt
join pizzas p
using (pizza_type_id)
join order_details od
using (pizza_id)
group by pt.name
order by revenue
desc limit 3;

-- 11 : Calculate the percentage contribution of each pizza type to total revenue. 

with pizza_revenue as (select pt.name, sum(od.quantity*p.price) as revenue from pizza_types pt
join pizzas p
using (pizza_type_id)
join order_details od
using (pizza_id)
group by pt.name
)
select name, (revenue / (select sum(revenue) from pizza_revenue ))*100 as Revenue_percent
from pizza_revenue
order by revenue_percent
desc;

-- 12 : Calculate the percentage contribution of each pizza type to total revenue.

with pizza_type_revenue as (select pt.category, sum(od.quantity*p.price) as revenue from pizza_types pt
join pizzas p
using (pizza_type_id)
join order_details od
using (pizza_id)
group by pt.category
)
select category, concat(Round((revenue / (select sum(revenue) from pizza_type_revenue ))*100,2), "%") as Revenue_percent
from pizza_type_revenue
order by revenue_percent
desc;

-- 13 :  Analyse the cumulative revenue generated over time. 

with cte as (select orders.date, 
sum(order_details.quantity * pizzas.price) as revenue 
from order_details join pizzas
on order_details.pizza_id = pizzas.pizza_id
join orders
on orders.order_id = order_details.order_id
group by orders.date)
select date, sum(revenue) over(order by date) as cum_revenue 
from cte;

-- 14 : Determine the top 3 most pizza types based on revenue for each pizza category.

select name, revenue from
(select category, name, revenue, 
rank() over(partition by category order by revenue desc) as rn
from 
(select pizza_types.category, pizza_types.name,
sum((order_details.quantity)*pizzas.price) as revenue
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.category, pizza_types.name) as a) as b
where rn <= 3;

-- or we can write the above query using CTE as shown below

with cte as (select pizza_types.category, pizza_types.name,
sum((order_details.quantity)*pizzas.price) as revenue
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.category, pizza_types.name),

cte2 as (select category, name, revenue, 
rank() over(partition by category order by revenue desc) as rn
from cte)

select name, revenue from cte2 where rn <= 3;