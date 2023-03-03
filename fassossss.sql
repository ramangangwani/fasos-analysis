
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');



CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');


CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');


CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');


CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2020 21:30:45','25km','25mins',null),
(8,2,'01-10-2020 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2020 18:50:20','10km','10minutes',null);


CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

-- how many rolls are orders
select count( roll_id)  from customer_orders

--how many unique customer orders are made
select count(distinct customer_id)  from customer_orders

--how many successfull orders are made by each driver
select driver_id,count(  order_id) from driver_order where cancellation not in ('Cancellation','Customer Cancellation') group by driver_id


-- how many each type of rols are delivered
with cte as 
(
select x.customer_id,x.order_id as ord_id, roll_name,cancellation,case when cancellation  in ('Cancellation','Customer Cancellation') then 'c' else 'nc' end as order_status from customer_orders as x
inner join rolls as y
on x.roll_id=y.roll_id
inner join driver_order as z
on x.order_id=z.order_id
)
select roll_name,count(ord_id) from cte
where order_status = 'nc'
group by roll_name

-- how many veg and non veg order were orderd by the customer
select customer_id,roll_name,count(order_id) from customer_orders as x
inner join  rolls as y
on x.roll_id=y.roll_id
group by  customer_id,roll_name

--what was max number of rolls deliverd in a single order
select top 1 x.order_id,count(roll_id) count_1,case when cancellation  in ('Cancellation','Customer Cancellation') then 'c' else 'nc' end as order_status,dense_rank() over (order by count(roll_id) desc) as rn from customer_orders as x
inner join driver_order as y
on y.order_id=x.order_id
group by x.order_id,cancellation

--for each customer  how many deleiverd rolls had at least 1 change and how many had no change
with new_customer_order(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(
select order_id,customer_id,roll_id,case when not_include_items is null or not_include_items = ' ' then '0' else not_include_items end as new_not_include_items ,case when extra_items_included =' ' or extra_items_included is null or extra_items_included = 'nan' then '0' else extra_items_included end as  new_extra_items_included ,order_date  from customer_orders

)
, new_driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) as
(
select order_id,driver_id,pickup_time,distance,duration,case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as cancel  from driver_order
)
,pipe as
(
select x.order_id as ord_id,driver_id,pickup_time,	distance,duration,cancellation,customer_id,roll_id,not_include_items,extra_items_included,order_date, case when not_include_items = '0' and extra_items_included = '0' then 'no change' else 'change' end as chang_not from new_driver_order as x
inner join new_customer_order as y
on x.order_id=y.order_id

where cancellation <> 0
)
select customer_id,chang_not,count(ord_id) from pipe
group by customer_id,chang_not



-- how many rolls were delivered that had both exclusions and extras
with new_customer_order(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(
select order_id,customer_id,roll_id,case when not_include_items is null or not_include_items = ' ' then '0' else not_include_items end as new_not_include_items ,case when extra_items_included =' ' or extra_items_included is null or extra_items_included = 'nan' then '0' else extra_items_included end as  new_extra_items_included ,order_date  from customer_orders

)
, new_driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) as
(
select order_id,driver_id,pickup_time,distance,duration,case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as cancel  from driver_order
)
,pipe as
(
select x.order_id as ord_id,driver_id,pickup_time,	distance,duration,cancellation,customer_id,roll_id,not_include_items,extra_items_included,order_date, case when not_include_items != '0' and extra_items_included != '0' then 'both included' else 'either 1 or not' end as chang_not from new_driver_order as x
inner join new_customer_order as y
on x.order_id=y.order_id
)
select chang_not,count(chang_not) from pipe
group by chang_not


--what was the total number of rolls ordered fro each hourof the day
select   concat(cast(DATEPART(hour,order_date) as varchar(50)),'-',cast(DATEPART(hour,order_date)+1 as varchar(50))) as hour_bucket,count(order_id)  from customer_orders as x
inner join rolls as y
on x.roll_id=y.roll_id
group by  concat(cast(DATEPART(hour,order_date) as varchar(50)),'-',cast(DATEPART(hour,order_date)+1 as varchar(50)))


select  DATEPART(hour,order_date) , count(order_id)  from customer_orders as x
inner join rolls as y
on x.roll_id=y.roll_id
group by DATEPART(hour,order_date) 

--what  was the number of orders for each day of the week
select datepart(weekday,order_date) as week_1,count(order_id) from customer_orders
group by datepart(weekday,order_date)


--whatw as the average tiem to reach in min it took for each driver at the fassos hq to pickup the order
with cte as 
(
select x.order_id,	customer_id,roll_id,	not_include_items,	extra_items_included,	order_date,	driver_id,pickup_time,distance,duration,cancellation
,abs(datepart(minute,order_date)-datepart(minute,pickup_time)) as minutes_2 from customer_orders as x
inner join driver_order as y
on y.order_id=x.order_id
where pickup_time is not null
)
,pipe as
(
select *,row_number() over(partition by order_id order by minutes_2) as rn from cte 
)
select driver_id,sum(minutes_2)/count(*) from pipe
where rn = 1
group by driver_id






-- is there any realtionship between the number of rolls and how long the order takes to prepare
with cte as 
(
select x.order_id as ord_id,	customer_id,roll_id,	not_include_items,	extra_items_included,	order_date,	driver_id,pickup_time,distance,duration,cancellation
,abs(datepart(minute,order_date)-datepart(minute,pickup_time)) as minutes_2 from customer_orders as x
inner join driver_order as y
on y.order_id=x.order_id
where pickup_time is not null
)
,pipe as
(
select *,row_number() over(partition by ord_id order by minutes_2) as rn from cte 
)
select ord_id,minutes_2,count(*) from pipe 
where rn=1
group by ord_id,minutes_2


-- waht was the average distance travelled for each customer
with cte as 
(
select x.order_id as ord_id,	customer_id,roll_id,	not_include_items,	extra_items_included,	order_date,	driver_id,pickup_time,distance,duration,cancellation
,abs(datepart(minute,order_date)-datepart(minute,pickup_time)) as minutes_2 from customer_orders as x
inner join driver_order as y
on y.order_id=x.order_id
where pickup_time is not null
)
,pipe as
(
select *,row_number() over(partition by ord_id order by minutes_2) as rn from cte 
)
,COP AS
(
select 	ord_id,	customer_id,	roll_id,	not_include_items,	extra_items_included,	order_date,	driver_id,	pickup_time,LTRIM(RTRIM(replace(distance,'km',''))) as distance,	duration,	cancellation,	minutes_2,	rn
 from pipe 
 )
 SELECT CUSTOMER_ID,AVG(CAST(DISTANCE AS DECIMAL)) FROM COP
GROUP BY  CUSTOMER_ID


--What was the differnce between the longest and shortest delivery tomes for all orders

select order_id,	driver_id,	pickup_time,	distance,cast(left(duration,2) as int) as duration,cancellation	 from driver_order

with cte as
(
select order_id,	driver_id,	pickup_time,	distance,case when duration like '%min%' then cast(left(duration,charindex('m',duration)-1) as int) else duration end as duration,cancellation	 from driver_order
)
select datediff(day,min(duration),max(duration)) from cte


-- waht wa sthe average speed for each driver for each delivery and do you notice any trend for these values
with cte as 
(
select order_id,	driver_id,	cast(LTRIM(RTRIM(replace(distance,'km',''))) as decimal) as distance	,case when duration like '%min%' then cast(left(duration,charindex('m',duration)-1) as int) else duration end as duration from driver_order
where LTRIM(RTRIM(replace(distance,'km',''))) is not null
)
select x.order_id,driver_id,avg(distance/duration) as speed,count(roll_id) as cnt from cte as x
inner join customer_orders as y
on x.order_id=y.order_id
group by x.order_id,driver_id

--what is the successfully delivery percentage for each driver

with cte as 
(
select cancellation,driver_id,case when cancellation like '%cancel%' then 0 else 1 end as point from driver_order
)
select driver_id,sum(point)*1.0/count(driver_id)*100 from cte
group by driver_id



