-- sprint 3:1: business understanding and data understanding
-- No SQL queries are required for sprint 1
-- 1. This sprint involves analyzing the ER diagram and ,
-- understanding the database schema.

-- Sprint 3:2: Database setup:

create database hotel_reservation_db;
use hotel_reservation_db;


-- 1. Guests Table (Parent)
create table guests (
    guest_id varchar(20) primary key,
    guest_name varchar(100) not null,
    city varchar(50),
    guest_type varchar(20),
    preferred_room_type varchar(20),
    loyalty_tier varchar(20),
    account_since varchar(20)
);
select*from guests;

-- 2. Hotels Table (Parent)
create table hotels (
    hotel_id varchar(20) primary key,
    hotel_name varchar(100) not null,
    city varchar(50),
    star_rating int,
    total_rooms int,
    opened_date varchar(20)
);
select*from hotels;

-- 3. Staff Table (Parent)
create table staff (
    staff_id varchar(20) primary key,
    staff_name varchar(100) not null,
    hire_date varchar(20),
    rating decimal(3,2),
    department varchar(30),
    is_active varchar(3) default 'Yes'
);
select*from staff;

-- 4. Rooms Table (Child of hotels)
create table rooms (
    room_id varchar(20) primary key,
    hotel_id varchar(20) not null,
    room_type varchar(20),
    floor_number int,
    max_occupancy int,
    price_per_night decimal(10,2),
    is_active varchar(3) default 'Yes',
    foreign key (hotel_id) references hotels(hotel_id)
);
select*from rooms;

-- 5. Bookings Table (Child of guests & hotels)
create table bookings (
    booking_id varchar(20) primary key,
    guest_id varchar(20) not null,
    hotel_id varchar(20) not null,
    booking_date varchar(20),
    room_type_requested varchar(20),
    booking_channel varchar(30),
    nights_booked int,
    total_amount decimal(12,2),
    foreign key (guest_id) references guests(guest_id),
    foreign key (hotel_id) references hotels(hotel_id)
);
select*from bookings;

-- 6. Stays Table (Child of bookings, rooms, & staff)
create table stays (
    stay_id varchar(20) primary key,
    booking_id varchar(20) not null,
    room_id varchar(20) not null,
    staff_id varchar(20) not null,
    check_in_date varchar(20),
    check_out_date varchar(20),
    status varchar(20),
    nights_stayed int,
    service_requests int,
    stay_duration_hrs int,
    foreign key (booking_id) references bookings(booking_id),
    foreign key (room_id) references rooms(room_id),
    foreign key (staff_id) references staff(staff_id)
);
select*from staff;
show tables ;
show databases;

select 'guests' as table_name, count(*) as total_rows from guests
union all
select 'hotels', count(*) from hotels
union all
select 'rooms', count(*) from rooms
union all
select 'staff', count(*) from staff
union all
select 'bookings', count(*) from bookings
union all
select 'stays', count(*) from stays;

set sql_safe_updates = 0;

-- Sprint 3: Basic Analysis / Data Exploration

-- 1. What is the total number of guests?
SELECT COUNT(*) AS total_guests
FROM guests;

-- 2. What is the total number of bookings?
SELECT COUNT(*) AS total_bookings
FROM bookings;

-- 3. What is the total number of stays?
SELECT COUNT(*) AS total_stays
FROM stays;

-- 4. What are the different room types available?
SELECT DISTINCT room_type
FROM rooms;

-- 5. How many staff members are currently active?
SELECT COUNT(*) AS active_staff
FROM staff
WHERE is_active = 'Yes';

-- 6. What are the different booking channels?
SELECT DISTINCT booking_channel
FROM bookings;

-- 7. What is the total booking amount across all bookings?
SELECT SUM(total_amount) AS total_booking_amount
FROM bookings;

-- 8. What is the average nights booked per booking?
SELECT AVG(nights_booked) AS average_nights_booked
FROM bookings;

-- Sprint 4: Objective Based Analysis
-- Udertsanding Booking Demand
-- Analytical Questions & Queries:
-- Q1. Number of bookings across hotels
 select hotel_id, count(*) as total_bookings
from bookings
group by hotel_id
order by total_bookings desc;

-- Q2. Bookings by booking channel
select booking_channel, count(*) as total_bookings
from bookings
group by booking_channel
order by total_bookings desc;

-- Q3. Average booking amount by booking channel
select booking_channel,
       avg(booking_amount) as average_booking_amount
from bookings
group by booking_channel
order by average_booking_amount desc;

-- Q4.Booking channel contribution %
select booking_channel,
       count(*) as total_bookings,
       round(count(*) * 100.0 / (select count(*) from bookings), 2) as booking_percentage
from bookings
group by booking_channel
order by booking_percentage desc;

-- 4.2 Understand Guest Booking Behaviour
-- Business Objective: Analyze guest purchasing patterns, segment high-value guests, and evaluate guest preferences.
-- Analytical Questions & Queries:
 -- Q1.which guests have made the highest number of bookings?
 select guest_id, count(*) as total_bookings
from bookings
group by guest_id
order by total_bookings desc;

-- Q2.which guests have the highest total booking amount?
select guest_id, sum(booking_amount) as total_booking_amount
from bookings
group by guest_id
order by total_booking_amount desc;

-- Q3.which hotels have the highest guest booking activity?
select hotel_id, count(*) as total_bookings
from bookings
group by hotel_id
order by total_bookings desc;


-- 4.4 Understand Staff and Room Performance
-- Business Objective: Evaluate resource utilization, room demand across room types, and staff workload and ratings.
-- Analytical Questions & Queries:
-- Q1.what is the average duration of completed stays?
select avg(datediff(check_out_date, check_in_date)) as average_stay_duration
from stays
where check_in_date is not null
and check_out_date is not null;

-- Q2.how does stay performance change over time?
select date_format(check_in_date, '%y-%m') as stay_month,
       stay_status,
       count(*) as total_stays
from stays
group by date_format(check_in_date, '%y-%m'), stay_status
order by stay_month;

-- Q3.What is the average stay duration handled by each staff member?
select st.staff_id,
       st.staff_name,
       avg(s.stay_duration_hrs) as average_stay_duration_hrs
from staff st
join stays s
on st.staff_id = s.staff_id
where s.stay_duration_hrs is not null
group by st.staff_id, st.staff_name
order by average_stay_duration_hrs desc;

-- 4.5 Identify Booking and Stay Problems
-- Business Objective: Uncover operational inefficiencies, service request drivers, and booking failure points.
-- Analytical Questions & Queries:
 -- 1. Do stays with higher service request counts correlate with longer stay durations or specific room capacities?
select stay_id, booking_id, service_requests from stays
where service_requests > 3;

 -- 2. Which booking channels have the highest cancellation and no-show rates?
select b.booking_channel, count(s.stay_id) as problem_stays
from bookings b
join stays s on b.booking_id = s.booking_id
where s.status in ('cancelled', 'no-show')
group by b.booking_channel;

-- Q3.Which hotels experience the most cancellations and no-shows?
select h.hotel_name,
       sum(case
           when s.status = 'cancelled' then 1
           else 0
       end) as cancellations,
       sum(case
           when s.status = 'no-show' then 1
           else 0
       end) as no_shows
from hotels h
join bookings b
on h.hotel_id = b.hotel_id
join stays s
on b.booking_id = s.booking_id
group by h.hotel_name
order by cancellations + no_shows desc;

select distinct status
from stays;

select distinct guest_type
from guests;
