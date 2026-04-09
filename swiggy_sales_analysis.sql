SELECT * from swiggy_data


--Data Cleaning & Validation
--Check for NULL Values in Each Column

SELECT
	SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
	SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city,
	SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
	SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_restaurant,
	SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location,
	SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_category,
	SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS null_dish,
	SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price,
	SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
	SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS null_rating_count
FROM swiggy_data;

--Blank or Empty Strings

SELECT *
FROM swiggy_data
WHERE
	State = '' OR City = '' OR Restaurant_Name = ''
	OR Location = '' OR Category = '' OR Dish_Name = '';


--Incorrect Data Types

SELECT
	State, City, Order_Date, Restaurant_Name, Location,
	Category, Dish_Name, Price_INR, Rating, Rating_Count,
	COUNT(*) AS cnt
FROM swiggy_data
GROUP BY
	State, City, Order_Date, Restaurant_Name, Location,
	Category, Dish_Name, Price_INR, Rating, Rating_Count
HAVING COUNT(*) > 1;


--Delete duplicates (keep the first)
-- cte - create a table expansion
WITH cte AS (
	SELECT *,
			ROW_NUMBER() OVER (

				PARTITION BY State, City, Order_Date, Restaurant_Name, Location, 
				Category, Dish_Name, Price_INR, Rating, Rating_Count
				ORDER BY (SELECT NULL)
			) AS rn
	FROM swiggy_data
)

DELETE FROM cte WHERE rn > 1;


--CREATE SCHEMA
--Create all Dimensions Table
--dim_date 


CREATE TABLE dim_date ( 
	Date_id INT IDENTITY(1,1) PRIMARY KEY, 
	Full_Date DATE, 
	Year INT,
	Month INT,
	Month_Name VARCHAR(20),
	Quarter INT, 
	Day INT, 
	Week INT 
);

select * from dim_date;


--dim location

CREATE TABLE dim_location ( 
	Location_ID INT IDENTITY(1,1) PRIMARY KEY,
	State VARCHAR(100),
	City VARCHAR(100),
	Location VARCHAR(200)
);

--dim_restaurant

CREATE TABLE dim_restaurant (
	Restaurant_ID INT IDENTITY(1,1) PRIMARY KEY,
	Restaurant_Name VARCHAR(200)
);

--dim_category

CREATE TABLE dim_category ( 
	Category_ID INT IDENTITY(1,1) PRIMARY KEY,
	Category VARCHAR(200)
);

--dim_dish

CREATE TABLE dim_dish (
	Dish_ID INT IDENTITY(1,1) PRIMARY KEY,
	Dish_Name VARCHAR(200)
);

select * from swiggy_data;


--FACT TABLE

CREATE TABLE Fact_swiggy_orders(
	Order_id INT IDENTITY(1,1) PRIMARY KEY,
	Date_id INT,
	Price_INR DECIMAL(10,2),
	Rating DECIMAL(4,2),
	Rating_Count INT,
	Location_id INT,
	Restaurant_id INT,
	Category_id INT,
	Dish_id INT

FOREIGN KEY (Date_id) REFERENCES dim_date(Date_id),
FOREIGN KEY (Location_id) REFERENCES dim_location(Location_id),
FOREIGN KEY (Restaurant_id) REFERENCES dim_restaurant(Restaurant_id),
FOREIGN KEY (Category_id) REFERENCES dim_category(Category_id),
FOREIGN KEY (Dish_id) REFERENCES dim_dish(Dish_id)
);

select * from Fact_swiggy_orders;

SELECT * from swiggy_data;


--Insert Data in all Tables

--dim_date

INSERT INTO dim_date(Full_Date, Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT
	Order_Date,
	YEAR(Order_Date),
	MONTH(Order_Date),
	DATENAME(MONTH, Order_Date),
	DATEPART(QUARTER, Order_Date),
	DAY(Order_Date),
	DATEPART(WEEK, Order_Date)
FROM swiggy_data
where Order_Date IS NOT NULL;

select * from dim_date;



--dim_location

INSERT INTO dim_location (State, City, Location)
SELECT DISTINCT
	State,
	City,
	Location
FROM swiggy_data;

SELECT * FROM dim_location;

--dim_restaurant

INSERT INTO dim_restaurant (Restaurant_Name)
SELECT DISTINCT
	Restaurant_Name
FROM swiggy_data;

SELECT * FROM dim_restaurant;


--dim_category
INSERT INTO dim_category (Category)
SELECT DISTINCT
	Category
FROM swiggy_data;

SELECT * FROM dim_category;


--dim_dish

INSERT INTO dim_dish (Dish_Name)
SELECT DISTINCT
	Dish_Name
FROM swiggy_data;

SELECT * FROM dim_dish;



--INSERT INTO FACT TABLE

INSERT INTO Fact_swiggy_orders
(
	date_id,
	Price_INR,
	Rating,
	Rating_Count,
	Location_id,
	restaurant_id,
	Category_id,
	dish_id
)
SELECT
	dd.date_id,
	s.Price_INR,
	s.Rating,
	s.Rating_Count,

	dl.Location_id,
	dr.restaurant_id,
	dc.category_id,
	dsh.dish_id
FROM swiggy_data s

JOIN dim_date dd
	ON dd.Full_Date = s.Order_Date


JOIN dim_location dl	
	ON dl.State = s.State
	AND dl.City = s.City
	AND dl.Location = s.Location


JOIN dim_restaurant dr
	ON dr.Restaurant_Name = s.Restaurant_Name

JOIN dim_category dc
	ON dc.Category = s.Category

JOIN dim_dish dsh 
	ON dsh.Dish_Name = s.Dish_Name;


SELECT * FROM Fact_swiggy_orders;

-- Final Table

SELECT * FROM Fact_swiggy_orders f
	JOIN dim_date d ON f.date_id = d.date_id
	JOIN dim_location l ON f.location_id = l.location_id
	JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
	JOIN dim_category c ON f.category_id = c.category_id
	JOIN dim_dish di ON f.dish_id = di.dish_id;


--KPI's
--Total Orders

SELECT count(*) AS Total_Orders
FROM Fact_swiggy_orders;

--Total Revenue (INR Million)

SELECT 
FORMAT (SUM(CONVERT(FLOAT,price_INR))/1000000, 'N2') + ' INR Million' 
AS Total_Revenue
FROM fact_swiggy_orders;


--Average Dish Price

SELECT 
FORMAT (AVG(CONVERT (FLOAT,price_INR)), 'N2') + ' INR'
AS Total_Revenue
FROM Fact_swiggy_orders;



--Average Rating

SELECT
AVG(Rating) AS Avg_Rating
FROM Fact_swiggy_orders



--Deep-Dive Business Analysis

--Monthly Order Trends

SELECT
	d.year,
	d.month,
	d.month_name,
	--count(*) AS Total_Orders
	SUM(Price_INR) AS Total_Revenue
FROM Fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year,
d.month,
d.month_name
ORDER BY SUM(Price_INR) DESC



--Quarterly Trend

SELECT
	d.year,
	d.quarter,
	count(*) AS Total_Orders
FROM Fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year,
d.quarter
ORDER BY count(*) DESC


--Yearly Orders

SELECT
	d.year,
	COUNT(*) AS total_orders
FROM Fact_swiggy_orders f
JOIN dim_date d ON f.Date_id = d.Date_id
GROUP BY d.year
ORDER BY count(*) DESC;


--Orders by Day of Week (Mon-Sun)

SELECT 
	DATENAME(WEEKDAY, d.full_date) AS day_name,
	COUNT(*) AS total_orders
FROM Fact_swiggy_orders f 
JOIN dim_date d ON f.Date_id = d.Date_id
GROUP BY DATENAME(WEEKDAY, d.full_date), 
DATEPART(WEEKDAY, d.full_date)
ORDER BY DATEPART(WEEKDAY, d.full_date);



--Top 10 Cities by Orders

SELECT TOP 10
	l.city,
	--COUNT(*) AS total_orders
	SUM(f.price_INR) AS Total_Revenue FROM Fact_swiggy_orders f
JOIN dim_location l
ON l.location_id = f.location_id
GROUP BY l.city
ORDER BY SUM(f.price_INR) DESC


--Revenue contribution by states

SELECT
	l.state,
	SUM(f.price_INR) AS Total_Revenue FROM fact_swiggy_orders f
JOIN dim_location l
ON l.location_id = f.location_id
GROUP BY l.state
ORDER BY SUM(f.price_INR) DESC



--Top 10 restaurants by orders

SELECT Top 10
	r.restaurant_name,
	SUM(f.price_INR) AS Total_Revenue FROM fact_swiggy_orders f
JOIN dim_restaurant r
ON r.restaurant_id = f.restaurant_id
GROUP BY r.restaurant_name
ORDER BY SUM(f.price_INR) DESC


--Top Categories by Order Volume

SELECT
	c.category,
	COUNT(*) AS total_orders
FROM Fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.category
ORDER BY total_orders DESC;


--Most Ordered Dishes

SELECT TOP 10
	d.dish_name,
	COUNT(*) AS order_count
FROM Fact_swiggy_orders f
JOIN dim_dish d ON f.dish_id = d.dish_id
GROUP BY d.dish_name
ORDER BY order_count DESC


ORDER BY total_orders DESC


--Most Ordered Dishes

SELECT
	d.dish_name,
	COUNT(*) AS order_count
FROM Fact_swiggy_orders f
JOIN dim_dish d ON f.dish_id = d.dish_id
GROUP BY d.dish_name
ORDER BY order_count DESC



--Total Revenue by State

SELECT
	l.state,
	SUM(CONVERT(FLOAT, f.price_inr)) AS total_revenue_inr
FROM Fact_swiggy_orders f

JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.state
ORDER BY total_revenue_inr DESC



--Cuisine Performance (Orders + Avg Rating)

SELECT
	c.category,
	COUNT(*) AS total_orders,
	AVG(CONVERT(FLOAT,f.rating)) AS avg_rating
FROM Fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY category
ORDER BY total_orders DESC;


--Total Orders by Price Range

SELECT
	CASE
		WHEN CONVERT(FLOAT, price_inr) <  100 THEN 'Under 100'
		WHEN CONVERT(FLOAT, price_inr) BETWEEN 100 AND 199 THEN '100-199'
		WHEN CONVERT(FLOAT, price_inr) BETWEEN 200 AND 299 THEN '200-299'
		WHEN CONVERT(FLOAT, price_inr) BETWEEN 300 AND 499 THEN '300-499'
		ELSE '500+'
	END AS price_range,
	COUNT(*) AS total_orders
FROM Fact_swiggy_orders
GROUP BY
	CASE
		WHEN CONVERT(FLOAT, price_inr) <  100 THEN 'Under 100'
		WHEN CONVERT(FLOAT, price_inr) BETWEEN 100 AND 199 THEN '100-199'
		WHEN CONVERT(FLOAT, price_inr) BETWEEN 200 AND 299 THEN '200-299'
		WHEN CONVERT(FLOAT, price_inr) BETWEEN 300 AND 499 THEN '300-499'
		ELSE '500+'
	END
ORDER BY total_orders DESC;



--Rating Count Distribution (1-5)

SELECT
	rating,
	COUNT(*) AS rating_count
FROM Fact_swiggy_orders
GROUP BY rating 
ORDER BY COUNT(*) DESC;



--SEE DATA IN ALL TABLES

SELECT * FROM dim_date;

SELECT * FROM dim_location;

SELECT * FROM dim_restaurant;

SELECT * FROM dim_category;

SELECT * FROM dim_dish;

SELECT * FROM Fact_swiggy_orders;

SELECT * FROM Fact_swiggy_orders f;