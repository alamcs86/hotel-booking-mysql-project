
create database temp1;

use temp1;



select * from users;  # 1000 - user_id, user_name, contact, age
select * from hotels;  # 300 - hotel_id, Hotel_Name, city, location, contact, total_rooms
select * from transactions;  # 800 - booking_id, transcation_id, transcation_mode, transaction_status
select * from ratings; # 800 - booking_id, rating
select * from bookings; # 800 - booking_id, hotel_id, user_id, booking_date, check_in_date, check_out_date, 
                             # num_of_rooms,room_type, price_per_day(per_room), total_discount%



#   1. List all hotels in a specific city 

select city, count(hotel_name) as No_of_hotel from hotels group by city order by city;

select * from hotels where city in ('delhi', 'Mumbai') order by city;

select * from hotels where city = 'delhi' OR CITY =  'Mumbai';

# 2. Find total number of bookings per hotel.

select b.hotel_id, h.hotel_name, count(b.booking_id) as no_of_bookings 
from bookings b
inner join hotels h
on h.hotel_id = b.hotel_id
group by hotel_id, hotel_name order by hotel_name;


# Q -     Find max bookings of which hotel.

select b.hotel_id, h.hotel_name, count(b.booking_id) as no_of_bookings 
from bookings b
inner join hotels h
on h.hotel_id = b.hotel_id
group by hotel_id, hotel_name order by no_of_bookings desc limit 1;


# Q  -   Get all users who have made more than 3 bookings.

select user_id, count(user_id) as No_of_bookings from bookings group by user_id having No_of_bookings > 3  ;


# Q  -   Show the total amount spent by each user.

select distinct user_id, (num_of_rooms*price_per_day) as total_amount_spent from bookings order by total_amount_spent desc;

-- without less 10%
select user_id, sum(num_of_rooms * price_per_day) as total_amount_spent from bookings group by user_id order by total_amount_spent desc;
select user_id, sum(num_of_rooms * price_per_day) as total_amount_spent from bookings group by user_id order by user_id desc;

# Q - Actual discounted asper original table

select user_id, hotel_id,
(price_per_day * num_of_rooms) as total_room_charges,
round(num_of_rooms * (price_per_day * total_discount_per / 100),2) as discounted_amount,
sum(round(num_of_rooms * (price_per_day - (price_per_day * total_discount_per / 100)),2)) as final_payment
from bookings
group by user_id, hotel_id, total_room_charges, discounted_amount
order by user_id;


# Q.  Show the total amount spent by each user.


select user_id, 
sum(round(num_of_rooms * (price_per_day - (price_per_day * total_discount_per / 100)),2)) as Total_amount_spent
from bookings
group by user_id
order by user_id;

# Q .  Which cities have the most hotels listed?

select city, count(*) as total_hotel
from hotels
group by city
order by total_hotel desc;

# Q . List all bookings with user id and hotel name.

select 
b.booking_id, b.booking_date, b.check_in_date, b.check_out_date, b.user_id, 
h.hotel_id, h.hotel_name, h.city, h.location
from bookings b
inner join hotels h
on b.hotel_id = h.hotel_id
order by hotel_name;

-- use window func & inner join

select 
b.booking_id, b.booking_date, b.check_in_date, b.check_out_date, b.user_id, b.price_per_day, b.room_type,
h.hotel_id, h.hotel_name, h.city, h.location,
row_number() over (partition by hotel_name order by hotel_name)
from bookings b
inner join hotels h
on b.hotel_id = h.hotel_id;

# Q .    Count all hotels city wise

select city, count(hotel_name) City_count from hotels group by city order by City_count desc;



# Q .  Find all users who stayed in hotels rated rating 'Excellent'.

select 
distinct b.user_id,
r.booking_id, r.ratings
from bookings b 
inner join ratings r
on b.booking_id = r.booking_id
where ratings = 'Excellent'
order by user_id;



# Q . Get the hotel names along with the total number of complete transactions & incomplete transaction.

select b.booking_id, 
h.hotel_id, h.hotel_name, 
t.transaction_status 
from bookings b
inner join hotels h
on b.hotel_id = h.hotel_id
inner join transactions t
on b.booking_id = t.booking_id
where transaction_status = 'complete';


# second query is below in both condition (complete and incomplete)

select 
h.hotel_id, h.hotel_name, 
count(case when t.transaction_status = 'complete' then 1 end) as complete_transaction,
count(case when t.transaction_status = 'incomplete' then 1 end) as incomplete_transaction
from bookings b
inner join hotels h
on b.hotel_id = h.hotel_id
inner join transactions t
on b.booking_id = t.booking_id
group by h.hotel_id, h.hotel_name
order by hotel_name asc;

# Q . Find the average stay duration per hotel.

 select h.hotel_name,
 avg(datediff(b.check_out_date, b.check_in_date)) as stay_duration_indays
 from bookings b
 inner join hotels h
 on b.hotel_id = h.hotel_id
 group by hotel_name
 order by h.hotel_name;
 

# Q . calculate monthly & hotel wise revenue 

# Q  Hotel wise revenue

with rev as 
(
select b.hotel_id, b.booking_id, h.hotel_name, 
datediff(b.check_out_date, b.check_in_date) * b.num_of_rooms * b.price_per_day as revenue,
round((b.price_per_day * b.total_discount_per / 100),2) as dis_amt 
from bookings b
inner join hotels h
on b.hotel_id = h.hotel_id
),
final_rev as
(
select hotel_id, booking_id, hotel_name, revenue, dis_amt, (revenue - dis_amt) as final_amount from rev
)
select hotel_name, sum(final_amount) as Grand_revenue 
from final_rev 
group by hotel_name 
order by Grand_revenue desc ;


-- Q  - Month wise revenue

with rev as 
(
select b.hotel_id, b.booking_id, h.hotel_name, b.check_in_date, 
datediff(b.check_out_date, b.check_in_date) * b.num_of_rooms * b.price_per_day as revenue,
round((b.price_per_day * b.total_discount_per / 100),2) as dis_amt 
from bookings b
inner join hotels h
on b.hotel_id = h.hotel_id
),
final_rev as
(
select hotel_id, booking_id, hotel_name, check_in_date, revenue, dis_amt, (revenue - dis_amt) as final_amount 
from rev
)
select month(check_in_date) as month_num, year(check_in_date) as years,  
sum(final_amount) 
from final_rev 
group by month(check_in_date), year(check_in_date) 
order by years, month_num;

# Q . Using CTE, rank users by total amount spent.

with amount as 
(
select distinct user_id,
datediff(check_out_date, check_in_date) * num_of_rooms * price_per_day as Amount_spent
from bookings 
)
select user_id, amount_spent,
rank () over (order by amount_spent) as s_rank
from amount;


# Q . Find the number of failed transactions per hotel using a CTE.

select * from transactions, bookings, hotels;

with fail_tran as
(
select t.booking_id, t.transaction_status,
b.hotel_id,
h.hotel_name
from transactions t
inner join bookings b
on t.booking_id = b.booking_id
inner join hotels h
on h.hotel_id = b.hotel_id
)
select hotel_name, count(transaction_status) as fail_trcount 
from fail_tran where transaction_status = 'incomplete' 
group by hotel_name
order by hotel_name;

# Q .  CTE and window functions, list top 5 high-spending users per city.

select * from bookings, hotels;

with amount as 
(
select distinct b.user_id, h.city,
sum(datediff(b.check_out_date, b.check_in_date) * b.num_of_rooms * b.price_per_day) as Amount_spent
from bookings b
inner join hotels h 
on b.hotel_id = h.hotel_id
group by b.user_id, h.city
),
rankk as (
select user_id, city, amount_spent,
rank() over (partition by city order by amount_spent desc) as Top_rank
from amount
) 

select * from rankk where top_rank <= 5;

# Q . Find the top 3 hotels in each city by total revenue.

select * from bookings, hotels;


with rev as 
(
select b.hotel_id, b.booking_id, 
h.city, h.hotel_name, 
datediff(b.check_out_date, b.check_in_date) * b.num_of_rooms * b.price_per_day as revenue,
round((b.price_per_day * b.total_discount_per / 100),2) as dis_amt 
from bookings b
inner join hotels h
on b.hotel_id = h.hotel_id
),
final_rev as
(
select hotel_id, booking_id, hotel_name, city, revenue, dis_amt, (revenue - dis_amt) as final_amount 
from rev
),
topcity as (
select city, hotel_name, sum(final_amount) as Grand_revenue,
rank() over (partition by city order by sum(final_amount) desc) as toprankcity
from final_rev
group by hotel_name, city
)
select * from topcity 
where toprankcity <= 3;

# Q .  Get the total number of users who have booked hotels in more than 2 different cities.

select * from users;
select * from bookings;


with user1 as 
(
select b.user_id, u.user_name,  b.booking_id, h.hotel_name, h.city 
from bookings b
inner join hotels h on b.hotel_id = h.hotel_id
inner join users u on u.user_id = b.user_id
 ),
 total_user as (
 select user_id, count(distinct city) as city_count from user1
 group by user_id
 having city_count >= 3
 )
 select count(*) as total_users from total_user;
      
-- solution 02 through subquery

SELECT COUNT(*) AS total_users
FROM (
    SELECT 
        b.user_id,
        COUNT(DISTINCT h.city) AS city_count
    FROM bookings b
    INNER JOIN hotels h ON b.hotel_id = h.hotel_id
    GROUP BY b.user_id
    HAVING COUNT(DISTINCT h.city) > 2
) AS multi_city_users;


# Q .  List the hotel(s) with the highest number of repeat customers. // user_id as customer

select * from users, hotels, bookings;

select distinct h.hotel_name,  count(u.user_name) as repeat_customer
from hotels h 
inner join bookings b on b.hotel_id = h.hotel_id
inner join users u on b.user_id = u.user_id
group by h.hotel_name
order by hotel_name;

# Q . Find out the maximum successful transaction amount by which mode. 

select * from transactions, bookings;

with rev as 
(
select 
b.booking_id, 
t.transaction_id, t.transaction_mode, t.transaction_status, 
datediff(b.check_out_date, b.check_in_date) * b.num_of_rooms * b.price_per_day as revenue,
round((b.price_per_day * b.total_discount_per / 100),2) as dis_amt 
from bookings b
inner join transactions t
on b.booking_id = t.booking_id
where transaction_status = 'complete'
),
final_rev as
(
select booking_id, transaction_id, transaction_mode, transaction_status,  revenue, dis_amt, (revenue - dis_amt) as final_amount 
from rev
)
select transaction_mode, sum(final_amount) as Grand_total_amt 
from final_rev
group by transaction_mode
order by grand_total_amt desc;

-- KPI & Metrics




select distinct user_id from bookings;
select sum(price_per_day) from bookings;
-- ALTER TABLE bookings
-- CHANGE `total_discount%` total_discount_per DECIMAL(10,2);