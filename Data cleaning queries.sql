create table uber

SELECT count(*) from uber

select * from uber

-- 1. alter data types 

alter table uber
alter column Date date

alter table uber
alter column Time time(0)

-- 2. update booking id and customer id and remove double quotes from their ids

update uber
set Booking_ID = REPLACE(Booking_ID,'"',''),
Customer_ID = REPLACE(Customer_ID,'"','')

-- to check if any quotes remain

SELECT *
FROM uber
WHERE Booking_ID LIKE '%"%'
   OR Customer_ID LIKE '%"%';

-- to check for leading/trailing spaces after the update:

SELECT *
FROM uber
WHERE Booking_ID <> LTRIM(RTRIM(Booking_ID))
   OR Customer_ID <> LTRIM(RTRIM(Customer_ID));

--3. Remove duplicates for booking ids and customer ids 

select count(distinct booking_id) as booking_count, count(distinct customer_id) as customer_count, count(*)
from uber

select booking_id, count(booking_id)
from uber
group by booking_id
having count(booking_id)>1
order by count(booking_id) desc

select customer_id, count(customer_id)
from uber
group by customer_id
having count(*)>1
order by COUNT(customer_id) desc

select * from uber
where Booking_ID='CNR3648267'

-- Check how different the records are.

SELECT Booking_ID,
       COUNT(*) AS RowCounts,
       COUNT(DISTINCT Customer_ID) AS Customers,
       COUNT(DISTINCT [Date]) AS Dates,
       COUNT(DISTINCT Booking_Status) AS Statuses
FROM uber
GROUP BY Booking_ID
HAVING COUNT(*) > 1
ORDER BY RowCounts DESC;


SELECT *
FROM uber
WHERE Booking_ID IN (
        SELECT Booking_ID
        FROM uber
        GROUP BY Booking_ID
        HAVING COUNT(*) > 1
    )
    ORDER BY Booking_ID;

-- to look for duplicate records
SELECT *,
       COUNT(*) AS duplicate_count
FROM uber
GROUP BY
    [Date],
    [Time],
    Booking_ID,
    Booking_Status,
    Customer_ID,
    Vehicle_Type,
    Pickup_Location,
    Drop_Location,
    Avg_VTAT,
    Avg_CTAT,
    Cancelled_Rides_by_Customer,
    Reason_for_cancelling_by_Customer,
    Cancelled_Rides_by_Driver,
    Driver_Cancellation_Reason,
    Incomplete_Rides,
    Incomplete_Rides_Reason,
    Booking_Value,
    Ride_Distance,
    Driver_Ratings,
    Customer_Rating,
    Payment_Method
HAVING COUNT(*) > 1;

select * from uber

-- 4. check for nulls

select *
from uber
where date is null
or time is null
or booking_id is null
or Customer_ID is null
or Booking_Status is null
or Vehicle_Type is null
or Pickup_Location is null
or Drop_Location is null

select count(avg_vtat) as vtat, count(avg_ctat) as ctat
from uber

select * from uber
where Avg_VTAT is null
and Booking_Status <> 'No Driver Found'

select * from uber
where Avg_CTAT is null
and Booking_Status not in ('Cancelled by Driver', 'Cancelled by Customer', 'No Driver Found')

select * from uber
where Booking_Status not in ('Cancelled by Driver', 'Cancelled by Customer', 'No Driver Found')
and Cancelled_Rides_by_Customer <> null
or Reason_for_cancelling_by_Customer <> null
or Cancelled_Rides_by_Driver <> null
or Driver_Cancellation_Reason <> null
or Incomplete_Rides <> null
or Incomplete_Rides_Reason <> null


-- 5. types of booking status, vehicle type, reasons for cancellation, payment method

select Booking_Status
from uber
group by Booking_Status

select Vehicle_Type
from uber
group by Vehicle_Type

select Reason_for_cancelling_by_Customer
from uber
group by Reason_for_cancelling_by_Customer

select Driver_Cancellation_Reason
from uber
group by Driver_Cancellation_Reason

select Incomplete_Rides
from uber
group by Incomplete_Rides

select Incomplete_Rides_Reason
from uber
group by Incomplete_Rides_Reason

select Payment_Method
from uber
group by Payment_Method

-- 6.check for incomplete rides – blank records

select * 
from uber
where Incomplete_Rides = ''

update uber
set Incomplete_Rides = 'null'
where booking_id = 'CNR7417664'

select * 
from uber
where booking_id = 'CNR7417664'

-- 7. check date range
select MAX(date) as max_date, MIN(date) as min_date
from uber

-- 8. ratings should range between 1 to 5

select *
from uber
where Driver_Ratings not between 1 and 5
or Customer_Rating not between 1 and 5

-- 9. validate monetary values
select * from uber
where Booking_Value<=0

-- 10. Validate distance 
select * from uber
where Ride_Distance<=0

-- 11. check outliers
SELECT
    MIN(Booking_Value),
    MAX(Booking_Value),
    AVG(Booking_Value)
FROM uber;

select * from uber
where Booking_Value > 3000 and Ride_Distance<3
order by Ride_Distance

-- cost per km value check

SELECT *,
       ROUND(
            Booking_Value / NULLIF(Ride_Distance,0),
            2
       ) AS Cost_Per_KM
FROM uber
where ROUND(Booking_Value / NULLIF(Ride_Distance,0),2)>500
ORDER BY Cost_Per_KM DESC

-- create a column to add outlier flag
ALTER TABLE uber
ADD Is_Outlier BIT;

update uber
set Is_Outlier =
    case
        when Booking_Value / NULLIF(Ride_Distance,0)>500 
        then 1
        else 0
    end


-- outliers for ride distance
SELECT
    MIN(Ride_Distance),
    MAX(Ride_Distance),
    AVG(Ride_Distance)
FROM uber;

-- 12 Completed rides shouldn't have cancellation reasons
select * from uber
where Booking_Status='Completed' 
and Cancelled_Rides_by_Customer <> null
or Cancelled_Rides_by_Driver <> null
or Incomplete_Rides <> null
or Incomplete_Rides_Reason <> null
or Reason_for_cancelling_by_Customer <> null
or Driver_Cancellation_Reason <> null

-- 13. Validate Cancellation Reason Exists

SELECT *
FROM uber
WHERE Booking_Status = 'Cancelled by Customer'
AND Reason_for_cancelling_by_Customer IS NULL;

SELECT *
FROM uber
WHERE Booking_Status = 'Cancelled by Driver'
AND Driver_Cancellation_Reason IS NULL;

-- 14. Check Location Quality
SELECT DISTINCT Pickup_Location
FROM uber
ORDER BY Pickup_Location;

SELECT DISTINCT Drop_Location
FROM uber
ORDER BY Drop_Location;

-- 15. Now i am planning to replace null to 0 for number of rides cancelled or incomplete and NA for reason and payment methods
-- backup
SELECT * INTO uber_bkp
FROM uber

select * from uber

select Cancelled_Rides_by_Customer, count(*) from uber
group by Cancelled_Rides_by_Customer

select Cancelled_Rides_by_Driver, count(*) from uber
group by Cancelled_Rides_by_Driver

select Incomplete_Rides, count(*) from uber
group by Incomplete_Rides

update uber
set Cancelled_Rides_by_Customer = 0
where Cancelled_Rides_by_Customer = 'null'

update uber
set Cancelled_Rides_by_Driver = 0
where Cancelled_Rides_by_Driver = 'null'

update uber
set Incomplete_Rides = 0
where Incomplete_Rides = 'null'

-- 16. change data type to BIT
alter table uber
alter column Incomplete_Rides BIT

alter table uber
alter column Cancelled_Rides_by_Customer BIT

alter table uber
alter column Cancelled_Rides_by_Driver BIT

-- 17. update reasons to NA
select Reason_for_cancelling_by_Customer, count(*) from uber
group by Reason_for_cancelling_by_Customer

select Driver_Cancellation_Reason, count(*) from uber
group by Driver_Cancellation_Reason

select Incomplete_Rides_Reason, count(*) from uber
group by Incomplete_Rides_Reason

select Payment_Method, count(*) from uber
group by Payment_Method

update uber
set Reason_for_cancelling_by_Customer = 'NA'
where Reason_for_cancelling_by_Customer = 'null'

update uber
set Driver_Cancellation_Reason = 'NA'
where Driver_Cancellation_Reason = 'null'

update uber
set Incomplete_Rides_Reason = 'NA'
where Incomplete_Rides_Reason = 'null'

update uber
set Payment_Method = 'NA'
where Payment_Method = 'null'


-- other queries
SELECT *
FROM uber
WHERE Booking_Status <> 'Completed'
AND (
    Driver_Ratings IS NOT NULL
    OR Customer_Rating IS NOT NULL
);

select vehicle_type, sum(booking_value)
from uber
where Booking_Status='Completed'
group by Vehicle_Type
order by sum(booking_value) desc

select * from uber where is_outlier=1
where payment_method = 'NA'

select * from uber 
where Booking_Status = 'Incomplete' not in ('Completed' , 'Incomplete') and Booking_Value is not null