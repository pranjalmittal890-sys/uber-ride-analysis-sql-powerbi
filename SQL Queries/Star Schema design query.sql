-- 1: Create a New Schema
CREATE SCHEMA dw;
GO

-- 2: Create Dimension Tables
CREATE TABLE dw.Dim_Date
(
    Date_Key INT PRIMARY KEY,
    Full_Date DATE,
    Day_Number INT,
    Day_Name VARCHAR(20),
    Month_Number INT,
    Month_Name VARCHAR(20),
    Quarter_Number INT,
    Year_Number INT
);

CREATE TABLE dw.Dim_Vehicle
(
    Vehicle_Key INT IDENTITY(1,1) PRIMARY KEY,
    Vehicle_Type VARCHAR(50)
);

CREATE TABLE dw.Dim_Status
(
    Status_Key INT IDENTITY(1,1) PRIMARY KEY,
    Booking_Status VARCHAR(50)
);

CREATE TABLE dw.Dim_Payment
(
    Payment_Key INT IDENTITY(1,1) PRIMARY KEY,
    Payment_Method VARCHAR(50)
);

CREATE TABLE dw.Dim_Location
(
    Location_Key INT IDENTITY(1,1) PRIMARY KEY,
    Location_Name VARCHAR(100)
);

CREATE TABLE dw.Dim_Time
(
    Time_Key INT PRIMARY KEY,
    Full_Time TIME,
    Hour_Number INT,
    Minute_Number INT,
    Second_Number INT,
    Time_Period VARCHAR(20)
);

-- Load Date Dimension
INSERT INTO dw.Dim_Date
(
    Date_Key,
    Full_Date,
    Day_Number,
    Day_Name,
    Month_Number,
    Month_Name,
    Quarter_Number,
    Year_Number
)

SELECT DISTINCT
       YEAR([Date])*10000
       + MONTH([Date])*100
       + DAY([Date]) AS Date_Key,

       CAST([Date] AS DATE),

       DAY([Date]),
       DATENAME(WEEKDAY,[Date]),

       MONTH([Date]),
       DATENAME(MONTH,[Date]),

       DATEPART(QUARTER,[Date]),
       YEAR([Date])

FROM dbo.uber;

-- Load Vehicle Dimension
INSERT INTO dw.Dim_Vehicle(Vehicle_Type)

SELECT DISTINCT Vehicle_Type
FROM dbo.uber;

-- Load Status Dimension
INSERT INTO dw.Dim_Status(Booking_Status)

SELECT DISTINCT Booking_Status
FROM dbo.uber

-- Load Payment Dimension

insert into dw.Dim_Payment(Payment_Method)

select distinct Payment_Method
from dbo.uber

-- Load Location Dimension
INSERT INTO dw.Dim_Location(Location_Name)

SELECT DISTINCT Pickup_Location
FROM dbo.uber

UNION

SELECT DISTINCT Drop_Location
FROM dbo.uber

-- Load Time Dim
INSERT INTO dw.Dim_Time
(
    Time_Key,
    Full_Time,
    Hour_Number,
    Minute_Number,
    Second_Number,
    Time_Period
)

SELECT DISTINCT

    DATEPART(HOUR,[Time])*10000 +
    DATEPART(MINUTE,[Time])*100 +
    DATEPART(SECOND,[Time]) AS Time_Key,

    CAST([Time] AS TIME),

    DATEPART(HOUR,[Time]),
    DATEPART(MINUTE,[Time]),
    DATEPART(SECOND,[Time]),

    CASE
        WHEN DATEPART(HOUR,[Time]) BETWEEN 5 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR,[Time]) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN DATEPART(HOUR,[Time]) BETWEEN 17 AND 21 THEN 'Evening'
        ELSE 'Night'
    END

FROM dbo.uber

-- Create Fact Table
CREATE TABLE dw.Fact_Rides
(
    Ride_Key BIGINT IDENTITY(1,1) PRIMARY KEY,

    Booking_ID VARCHAR(50),
    Customer_ID VARCHAR(50),

    Date_Key INT,
    Time_Key INT,

    Vehicle_Key INT,
    Status_Key INT,
    Payment_Key INT,

    Pickup_Location_Key INT,
    Drop_Location_Key INT,

    Avg_VTAT FLOAT,
    Avg_CTAT FLOAT,

    Cancelled_Rides_by_Customer BIT,
    Cancelled_Rides_by_Driver BIT,
    Incomplete_Rides BIT,

    Customer_Cancellation_Reason VARCHAR(255),
    Driver_Cancellation_Reason VARCHAR(255),
    Incomplete_Ride_Reason VARCHAR(255),

    Booking_Value DECIMAL(10,2),
    Ride_Distance DECIMAL(10,2),

    Driver_Ratings DECIMAL(3,2),
    Customer_Rating DECIMAL(3,2),

    CONSTRAINT FK_Fact_Date
        FOREIGN KEY(Date_Key)
        REFERENCES dw.Dim_Date(Date_Key),

    CONSTRAINT FK_Fact_Time
        FOREIGN KEY(Time_Key)
        REFERENCES dw.Dim_Time(Time_Key),

    CONSTRAINT FK_Fact_Vehicle
        FOREIGN KEY(Vehicle_Key)
        REFERENCES dw.Dim_Vehicle(Vehicle_Key),

    CONSTRAINT FK_Fact_Status
        FOREIGN KEY(Status_Key)
        REFERENCES dw.Dim_Status(Status_Key),

    CONSTRAINT FK_Fact_Payment
        FOREIGN KEY(Payment_Key)
        REFERENCES dw.Dim_Payment(Payment_Key),

    CONSTRAINT FK_Fact_Pickup
        FOREIGN KEY(Pickup_Location_Key)
        REFERENCES dw.Dim_Location(Location_Key),

    CONSTRAINT FK_Fact_Drop
        FOREIGN KEY(Drop_Location_Key)
        REFERENCES dw.Dim_Location(Location_Key)
);

INSERT INTO dw.Fact_Rides
(
    Booking_ID,
    Customer_ID,

    Date_Key,
    Time_Key,

    Vehicle_Key,
    Status_Key,
    Payment_Key,

    Pickup_Location_Key,
    Drop_Location_Key,

    Avg_VTAT,
    Avg_CTAT,

    Cancelled_Rides_by_Customer,
    Cancelled_Rides_by_Driver,
    Incomplete_Rides,

    Customer_Cancellation_Reason,
    Driver_Cancellation_Reason,
    Incomplete_Ride_Reason,

    Booking_Value,
    Ride_Distance,

    Driver_Ratings,
    Customer_Rating
)

SELECT

    u.Booking_ID,
    u.Customer_ID,

    YEAR(u.[Date])*10000 +
    MONTH(u.[Date])*100 +
    DAY(u.[Date]) AS Date_Key,

    DATEPART(HOUR,u.[Time])*10000 +
    DATEPART(MINUTE,u.[Time])*100 +
    DATEPART(SECOND,u.[Time]) AS Time_Key,

    dv.Vehicle_Key,
    ds.Status_Key,
    dp.Payment_Key,

    pl.Location_Key,
    dl.Location_Key,

    u.Avg_VTAT,
    u.Avg_CTAT,

    u.Cancelled_Rides_by_Customer,
    u.Cancelled_Rides_by_Driver,
    u.Incomplete_Rides,

    u.Reason_for_cancelling_by_Customer,
    u.Driver_Cancellation_Reason,
    u.Incomplete_Rides_Reason,

    u.Booking_Value,
    u.Ride_Distance,

    u.Driver_Ratings,
    u.Customer_Rating

FROM dbo.uber u

INNER JOIN dw.Dim_Vehicle dv
    ON u.Vehicle_Type = dv.Vehicle_Type

INNER JOIN dw.Dim_Status ds
    ON u.Booking_Status = ds.Booking_Status

INNER JOIN dw.Dim_Payment dp
    ON u.Payment_Method = dp.Payment_Method

INNER JOIN dw.Dim_Location pl
    ON u.Pickup_Location = pl.Location_Name

INNER JOIN dw.Dim_Location dl
    ON u.Drop_Location = dl.Location_Name;

    ---------------------------------------------------------------------
