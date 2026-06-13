-- total bookings
select count(booking_id)
from [dw].[Fact_Rides]

-- total unique bookings
select count(distinct booking_id)
from [dw].[Fact_Rides]

-- total revenue
select sum(booking_value) from [dw].[Fact_Rides]

-- total count of payment methods
select p.payment_method, count(*) as total_count
from [dw].[Fact_Rides] f join [dw].[Dim_Payment] p
on f.payment_key = p.payment_key
where p.payment_method <> 'NA'
group by p.payment_method
order by total_count desc

-- revenue per vehicle type 
select v.Vehicle_type, sum(f.booking_value) as Revenue
from [dw].[Dim_Vehicle] v join [dw].[Fact_Rides] f
on v.vehicle_key = f.vehicle_key
group by v.vehicle_type
order by Revenue desc

--total %age revenue by vehicle
select v.vehicle_type, cast(100.0* sum(f.booking_value)/sum(sum(f.booking_value)) over() as decimal(10,2)) as prcnt_total
from [dw].[Dim_Vehicle] v join [dw].[Fact_Rides] f
on v.vehicle_key = f.vehicle_key
group by v.vehicle_type

-- Revenue by Payment Method
select p.payment_method, sum(f.booking_value) as revenue, 
cast(100.0* sum(f.booking_value)/sum(sum(f.booking_value)) over() as decimal(10,2)) as rev_prcnt
from [dw].[Fact_Rides] f join [dw].[Dim_Payment] p
on f.payment_key = p.payment_key
group by p.payment_method
order by revenue desc

-- avg customer rating
select avg(customer_rating)
from [dw].[Fact_Rides]

-- avg booking value
select avg(booking_value)
from [dw].[Fact_Rides]

-- avg ride distance
select avg(ride_distance)
from [dw].[Fact_Rides]

-- total rides by vehicle type
select v.Vehicle_type, count(*) as vehicle_count
from [dw].[Fact_Rides] f join [dw].[Dim_Vehicle] v
on v.vehicle_key = f.vehicle_key
group by v.vehicle_type
order by vehicle_count desc

-- total rides by booking status
select s.Booking_status, count(*) as total_rides
from [dw].[Dim_Status] s join [dw].[Fact_Rides] f
on s.status_key = f.status_key
group by s.Booking_status
order by total_rides desc

-- total successful trips
select count(*) as total_successful_Trips
from [dw].[Fact_Rides] f join [dw].[Dim_Status] s
on f.Status_Key = s.Status_Key
where s.Booking_Status='Completed'

-- completion rate
select v.vehicle_type, cast(
		100*
			sum(
	    case
			when s.Booking_status like 'Completed'
			then 1
			else 0
		end)/ count(*) as decimal(10,2)) as Completion_Rate
from [dw].[Fact_Rides] f join [dw].[Dim_Status] s
on f.status_key = s.status_key
join [dw].[Dim_Vehicle] v
on f.vehicle_key = v.vehicle_key
group by v.vehicle_type

-- Cancellation Rate - 25% cancellation rate
select round(
		100*
			sum(
	    case
			when s.Booking_status like 'Cancelled%'
			then 1
			else 0
		end)/ count(*),2) as Cancellation_Rate
from [dw].[Fact_Rides] f join [dw].[Dim_Status] s
on f.status_key = s.status_key

-- overall Successful rides %age
select cast(round(
		100.0*	
			sum(
				case
					when s.booking_status = 'Completed'
					then 1
					else 0
				end
				)/count(*),2) as decimal(10,2)) as success_rate
from [dw].[Fact_Rides] f join [dw].[Dim_Status] s
on f.status_key = s.status_key

-- total cancelled rides
select count(*) as total_successful_Trips
from [dw].[Fact_Rides] f join [dw].[Dim_Status] s
on f.Status_Key = s.Status_Key
where s.Booking_Status like 'Cancelled%'

----------- cumulative %age
WITH VehicleRevenue AS
(
    SELECT
        v.Vehicle_Type,
        SUM(f.Booking_Value) AS Revenue
    FROM dw.Fact_Rides f
    JOIN dw.Dim_Vehicle v
        ON f.vehicle_key = v.vehicle_key
    GROUP BY v.Vehicle_Type
)

SELECT
    Vehicle_Type,
    Revenue,

    ROUND(
        Revenue * 100.0 /
        SUM(Revenue) OVER (),
    2) AS Revenue_Percentage,

    SUM(Revenue) OVER (
        ORDER BY Revenue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Running_Revenue,

    ROUND(
        SUM(Revenue) OVER (
            ORDER BY Revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) * 100.0
        /
        SUM(Revenue) OVER (),
    2) AS Cumulative_Percentage

FROM VehicleRevenue
ORDER BY Revenue DESC;

-- Which type of vehicle gets most cancelled and which completes rides
select v.Vehicle_Type, count(*) as total_count,
cast(100.0*count(*)/sum(count(*)) over() as decimal(10,2))
FROM [dw].[Fact_Rides] f join [dw].[Dim_Vehicle] v
on f.vehicle_key = v.vehicle_key
join [dw].[Dim_Status] s
on f.Status_Key = s.Status_Key
where s.Booking_Status like 'Cancelled%'
group by v.vehicle_type
order by total_count desc

-- Cancelled rides by time period (count and %age)
select v.Vehicle_Type, t.Time_Period, count(*) as total_count,
cast(100.0*count(*)/sum(count(*)) over() as decimal(10,2)) as prcnt_rides
FROM [dw].[Fact_Rides] f join [dw].[Dim_Vehicle] v
on f.vehicle_key = v.vehicle_key
join [dw].[Dim_Status] s
on f.Status_Key = s.Status_Key
join [dw].[Dim_Time] t
on f.Time_Key = t.Time_Key
where s.Booking_Status like 'Cancelled%'
group by v.vehicle_type, t.Time_Period
order by v.vehicle_type

-- total rides per booking status per vehicle type 
select v.Vehicle_type, s.Booking_Status, count(*) as vehicle_count
from [dw].[Fact_Rides] f join [dw].[Dim_Vehicle] v
on v.vehicle_key = f.vehicle_key
join [dw].[Dim_Status] s
on f.Status_Key = s.Status_Key
group by v.vehicle_type, s.Booking_Status
order by vehicle_count desc

-- %age of cancel reasons by driver - out of total cancelled, %age of that
select v.Vehicle_Type, f.driver_cancellation_reason, count(*) as cancellation_count,
cast(100.0* count(*)/sum(count(*)) over() as decimal(10,2)) as prcntCount
from [dw].[Fact_Rides] f join [dw].[Dim_Vehicle] v
on f.vehicle_key = v.Vehicle_Key
where f.driver_cancellation_reason <> 'NA'
group by f.driver_cancellation_reason, v.Vehicle_Type
order by cancellation_count desc

-- %age of cancel reasons by customer - out of total cancelled, %age of that
select  v.Vehicle_Type, f.customer_cancellation_reason, count(*) as cancellation_count,
cast(100.0* count(*)/sum(count(*)) over() as decimal(10,2)) as prcntCount
from [dw].[Fact_Rides] f join [dw].[Dim_Vehicle] v
on f.vehicle_key = v.Vehicle_Key
where customer_cancellation_reason <> 'NA'
group by customer_cancellation_reason, v.Vehicle_Type
order by cancellation_count desc

-- rides total cancelled by driver
select count(*) as total,
sum(case when Cancelled_rides_by_driver=1 then 1 else 0 end) as rides,
cast(100.0* 
sum(case when Cancelled_rides_by_driver=1 then 1 else 0 end)/sum(count(*)) over() as decimal(10,2)) as prcntCount
from [dw].[Fact_Rides]

-- rides total cancelled by customer
select count(*) as total,
sum(case when Cancelled_Rides_by_Customer=1 then 1 else 0 end) as rides,
cast(100.0* 
sum(case when Cancelled_Rides_by_Customer=1 then 1 else 0 end)/sum(count(*)) over() as decimal(10,2)) as prcntCount
from [dw].[Fact_Rides]

-- Most Common Customer Cancellation Reasons
select customer_cancellation_reason, count(*) as total_count
from [dw].[Fact_Rides]
where customer_cancellation_reason <> 'NA'
group by customer_cancellation_reason
order by total_count desc

-- Most Common Driver Cancellation Reasons
select driver_cancellation_reason, count(*) as cancellation_count
from [dw].[Fact_Rides]
where driver_cancellation_reason <> 'NA'
group by driver_cancellation_reason
order by cancellation_count desc

-- %age of each status booking
SELECT s.Booking_Status, COUNT(*) AS Total_Rides,
    CAST(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS Status_Percentage
FROM [dw].[Fact_Rides] f
JOIN [dw].[Dim_Status] s
    ON f.Status_Key = s.Status_Key
GROUP BY s.Booking_Status
ORDER BY Total_Rides DESC;

-- Revenue by Month, number of rides booked
select d.month_name, sum(f.booking_value) as revenue_month, count(*) as total_rides
from [dw].[Fact_Rides] f join [dw].[Dim_Date] d
on f.date_key = d.date_key
group by d.month_name
order by revenue_month desc

-- Peak Booking Hours
select t.hour_number, count(*) as total_rides
from [dw].[Fact_Rides] f join [dw].[Dim_Time] t
on f.time_key = t.time_key
group by t.hour_number
order by total_rides desc

-- trips by peak hours and status wise
select t.hour_number, count(*) as total_rides,
count(case when s.booking_status = 'Completed' then f.booking_id end) as completed_rides,
count(case when s.booking_status = 'Incomplete' then  f.booking_id end) as incomplete_rides,
count(case when s.booking_status = 'Cancelled by Customer' then  f.booking_id end) as customer_cancelled_rides,
count(case when s.booking_status = 'Cancelled by Driver' then  f.booking_id end) as driver_cancelled_rides,
count(case when s.booking_status = 'No Driver Found' then  f.booking_id end) as no_driver_rides
from [dw].[Fact_Rides] f join [dw].[Dim_Time] t
on f.time_key = t.time_key
join [dw].[Dim_Status] s
on f.status_key = s.status_key
group by t.hour_number
order by total_rides desc

-- Revenue by Time Period
select t.time_period, sum(booking_value) as revenue
from [dw].[Fact_Rides] f join [dw].[Dim_Time] t
on f.time_key = t.time_key
group by t.time_period
order by revenue desc

-- Revenue by day of week
SELECT
    dd.Day_Name,
    SUM(fr.Booking_Value) AS Revenue
FROM dw.Fact_Rides fr
JOIN dw.Dim_Date dd
    ON fr.Date_Key = dd.Date_Key
GROUP BY dd.Day_Name
order by Revenue desc

-- Peak days of uber used, and lowest days
select dd.Day_Name, count(*) as rides, sum(fr.Booking_Value) as revenue, avg(fr.Booking_Value) as avg_value,
dense_rank() over (order by count(*) desc) as rides_rank
from dw.Fact_Rides fr
JOIN dw.Dim_Date dd
on fr.Date_Key = dd.Date_Key
group by dd.Day_Name
order by revenue desc

-- Top Pickup Locations
select l.location_name, count(*) as pickup_loc_count
from dw.Fact_Rides f join [dw].[Dim_Location] l
on f.pickup_location_key = l.location_key
where f.vehicle_key=6
group by l.location_name
order by pickup_loc_count desc

-- Top Drop Locations
select l.location_name, count(*) as drop_loc_count
from dw.Fact_Rides f join [dw].[Dim_Location] l
on f.drop_location_key = l.location_key
where f.vehicle_key=6
group by l.location_name
order by drop_loc_count desc

-- Most Popular Routes
SELECT v.vehicle_type,
    p.Location_Name AS Pickup,
    d.Location_Name AS Drop_Location,
    COUNT(*) AS Trips
FROM dw.Fact_Rides fr

JOIN dw.Dim_Location p
    ON fr.Pickup_Location_Key = p.Location_Key

JOIN dw.Dim_Location d
   ON fr.Drop_Location_Key = d.Location_Key
join [dw].[Dim_Vehicle] v
on fr.vehicle_key = v.vehicle_key
GROUP BY
v.vehicle_Type,
    p.Location_Name,
   d.Location_Name

ORDER BY Trips DESC;

-- Average Driver Rating by Vehicle
select v.vehicle_type, avg(f.driver_ratings) as avg_driver_ratings
FROM dw.Fact_Rides f join [dw].[Dim_Vehicle] v
on f.vehicle_key = v.vehicle_key
group by v.vehicle_type

-- Average Customer Rating by Vehicle
select v.vehicle_type, avg(f.Customer_Rating) as avg_customer_ratings, count(*) as trips
FROM dw.Fact_Rides f join [dw].[Dim_Vehicle] v
on f.vehicle_key = v.vehicle_key
group by v.vehicle_type
order by trips desc

-- Longest Average Wait Time by Vehicle
select v.vehicle_type, avg(f.Avg_VTAT) as avg_time
FROM dw.Fact_Rides f join [dw].[Dim_Vehicle] v
on f.vehicle_key = v.vehicle_key
group by v.vehicle_type
order by avg_time desc

-- Revenue Contribution %
select v.Vehicle_Type, sum(f.booking_value) as revenue,
cast(100.0* sum(f.booking_value)/sum(sum(f.booking_value)) over() as decimal(10,2)) as revenue_prctage
FROM [dw].[Fact_Rides] f join [dw].[Dim_Vehicle] v
on f.vehicle_key = v.vehicle_key
group by v.vehicle_type
order by revenue_prctage desc

-- avg price of uber booked
select v.Vehicle_Type, avg(f.booking_value) as avg_price
FROM [dw].[Fact_Rides] f join [dw].[Dim_Vehicle] v
on f.vehicle_key = v.vehicle_key
group by v.vehicle_type
order by avg_price desc

-- pivot table calcs
SELECT
    v.Vehicle_Type,

    COUNT(CASE
        WHEN s.Booking_Status = 'Completed'
        THEN f.Booking_ID
    END) AS Completed,

    CAST(
        100.0 *
        COUNT(CASE
            WHEN s.Booking_Status = 'Completed'
            THEN f.Booking_ID
        END)
        / COUNT(f.Booking_ID)
        as decimal(10,2)
    ) AS Completed_Pct,

    COUNT(CASE
        WHEN s.Booking_Status = 'Cancelled by Customer'
        THEN f.Booking_ID
    END) AS Cancelled_By_Customer,

    cast(
        100.0 *
        COUNT(CASE
            WHEN s.Booking_Status = 'Cancelled by Customer'
            THEN f.Booking_ID
        END)
        / COUNT(f.Booking_ID) as decimal(10,2)
    ) AS Cancelled_By_Customer_Pct,

    COUNT(CASE
        WHEN s.Booking_Status = 'Cancelled by Driver'
        THEN f.Booking_ID
    END) AS Cancelled_By_Driver,

    cast(
        100.0 *
        COUNT(CASE
            WHEN s.Booking_Status = 'Cancelled by Driver'
            THEN f.Booking_ID
        END)
        / COUNT(f.Booking_ID) as decimal(10,2)
    ) AS Cancelled_By_Driver_Pct,

    COUNT(CASE
        WHEN s.Booking_Status = 'Incomplete'
        THEN f.Booking_ID
    END) AS Incomplete,

    cast(
        100.0 *
        COUNT(CASE
            WHEN s.Booking_Status = 'Incomplete'
            THEN f.Booking_ID
        END)
        / COUNT(f.Booking_ID) as decimal(10,2)
    ) AS Incomplete_Pct,

    COUNT(CASE
        WHEN s.Booking_Status = 'No Driver Found'
        THEN f.Booking_ID
    END) AS No_Driver_Found,

    cast(
        100.0 *
        COUNT(CASE
            WHEN s.Booking_Status = 'No Driver Found'
            THEN f.Booking_ID
        END)
        / COUNT(f.Booking_ID) as decimal(10,2)
    ) AS No_Driver_Found_Pct,

    COUNT(f.Booking_ID) AS Total_Rides

FROM dw.Fact_Rides f
JOIN dw.Dim_Vehicle v
    ON f.Vehicle_Key = v.Vehicle_Key
JOIN dw.Dim_Status s
    ON f.Status_Key = s.Status_Key

GROUP BY v.Vehicle_Type;

-- avg distance traveled by cabs
select v.Vehicle_Type, cast(avg(f.Ride_Distance) as decimal(10,2)) as avg_dist, cast(sum(f.Ride_Distance) as decimal(10,2)) as total_dist
FROM dw.Fact_Rides f
JOIN dw.Dim_Vehicle v
    ON f.Vehicle_Key = v.Vehicle_Key
group by v.Vehicle_Type
