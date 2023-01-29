-- 1. Tulis query untuk mendapatkan jumlah customer tiap bulan yang melakukan order pada tahun 1997.
select month([OrderDate]) as Bulan, count (distinct[CustomerID]) as Total_Customer from Orders
where year([OrderDate]) = 1997
group by month([OrderDate]);

-- 2. Tulis query untuk mendapatkan nama employee yang termasuk Sales Representative.
select [EmployeeID]
      ,[LastName]
      ,[FirstName]
FROM [Northwind].[dbo].[Employees]
where [Title] = 'Sales Representative';

-- 3.	Tulis query untuk mendapatkan top 5 nama produk yang quantitynya paling banyak diorder pada bulan Januari 1997.
SELECT TOP (5) OrderDetails.[OrderID], 
			OrderDetails.[Quantity], 
			Products.[ProductName], 
			Orders.[OrderDate] 
FROM (([Northwind].[dbo].[Order Details] AS OrderDetails
INNER JOIN [Northwind].[dbo].[Products] AS Products 
ON OrderDetails.[ProductID]=Products.[ProductID]) 
INNER JOIN [Northwind].[dbo].[Orders] AS Orders
ON OrderDetails.[OrderID]=Orders.[OrderID])
WHERE year(Orders.[OrderDate]) = 1997 
AND month(Orders.[OrderDate]) = 1
ORDER BY OrderDetails.[Quantity] DESC;

-- 4. Tulis query untuk mendapatkan nama company yang melakukan order Chai pada bulan Juni 1997.
SELECT OrderDetails.[OrderID], 
		Products.[ProductName], 
		Orders.[OrderDate], 
		Customers.[CompanyName]
  
FROM ((([Northwind].[dbo].[Order Details] AS OrderDetails
INNER JOIN [Northwind].[dbo].[Products] AS Products 
ON OrderDetails.[ProductID]=Products.[ProductID]) 
INNER JOIN [Northwind].[dbo].[Orders] AS Orders
ON OrderDetails.[OrderID]=Orders.[OrderID])
INNER JOIN [Northwind].[dbo].[Customers] AS Customers
ON Customers.[CustomerID]=Orders.[CustomerID]);

-- 5. Tulis query untuk mendapatkan jumlah OrderID yang pernah melakukan pembelian (unit_price dikali quantity) 
-- <=100, 100<x<=250, 250<x<=500, dan >500.
WITH Y AS (
SELECT OrderDetails.[OrderID], 
	  SUM(OrderDetails.[UnitPrice] * OrderDetails.[Quantity]) AS TotalPrice
FROM [Northwind].[dbo].[Order Details] AS OrderDetails 
GROUP BY OrderDetails.[OrderID]),

X AS (
SELECT *,
CASE WHEN (Y.[TotalPrice]) <=100 THEN 'A'
WHEN (Y.[TotalPrice]) > 100 AND (Y.[TotalPrice]) <=250 THEN 'B'
WHEN (Y.[TotalPrice]) > 250 AND (Y.[TotalPrice]) <=500 THEN 'C'
ELSE 'D' END AS LABELNYA
FROM Y)

Select LABELNYA, count(DISTINCT [OrderID]) AS TOTAL_ORDERID
From X
Group by LABELNYA;

-- 6. Tulis query untuk mendapatkan Company name pada tabel customer yang melakukan pembelian di atas 500 pada tahun 1997.
SELECT Customers.[CompanyName],
		SUM(OrderDetails.[UnitPrice] * OrderDetails.[Quantity]) AS TotalPrice
FROM (([Northwind].[dbo].[Customers] AS Customers
INNER JOIN [Northwind].[dbo].[Orders] AS Orders
ON Customers.[CustomerID]=Orders.[CustomerID])
INNER JOIN [Northwind].[dbo].[Order Details] AS OrderDetails
ON Orders.[OrderID] = OrderDetails.[OrderID])
WHERE (OrderDetails.[UnitPrice] * OrderDetails.[Quantity]) > 500
AND year(Orders.[OrderDate]) = 1997
GROUP BY Customers.[CompanyName];

-- 7. Tulis query untuk mendapatkan nama produk yang merupakan Top 5 sales tertinggi tiap bulan di tahun 1997.
WITH DATAS AS (
SELECT
  month(O.[OrderDate]) AS MONTH,
  P.[ProductName],
  SUM(OD.[UnitPrice] * OD.[Quantity]) AS TotalPrice
FROM [Northwind].[dbo].[Products] AS P
INNER JOIN [Northwind].[dbo].[Order Details] AS OD
  ON P.[ProductID] = OD.[ProductID]
INNER JOIN [Northwind].[dbo].[Orders] AS O
  ON OD.[OrderID] = O.[OrderID]
WHERE year(O.[OrderDate]) = 1997
GROUP BY
  month(O.[OrderDate]),
  P.[ProductName]
),

TOP_SALES_PER_MONTH AS (
SELECT *,
  ROW_NUMBER() OVER (PARTITION BY [MONTH] ORDER BY TotalPrice DESC) AS RANKING_SALES
FROM DATAS
)

SELECT
  MONTH,
  ProductName, TotalPrice
FROM TOP_SALES_PER_MONTH
WHERE RANKING_SALES BETWEEN 1 AND 5;

--8. Buatlah view untuk melihat Order Details yang berisi OrderID, ProductID, ProductName, UnitPrice, Quantity, Discount, Harga setelah diskon.
CREATE VIEW NOMOR_8 AS 
SELECT OD.[OrderID], 
P.[ProductID], 
P.[ProductName], 
OD.[UnitPrice], 
OD.[Quantity], 
OD.[Discount],
((OD.[UnitPrice] * OD.[Quantity]) - ((OD.[UnitPrice] * OD.[Quantity]) * OD.[Discount])) AS HARGA
FROM [Northwind].[dbo].[Products] AS P
INNER JOIN [Northwind].[dbo].[Order Details] AS OD
 ON P.[ProductID] = OD.[ProductID];

SELECT * FROM NOMOR_8;

-- 9 Buatlah procedure Invoice untuk memanggil CustomerID, CustomerName/company name, OrderID, 
-- OrderDate, RequiredDate, ShippedDate jika terdapat inputan CustomerID tertentu.
CREATE VIEW NOMOR_9 AS
SELECT	C.[CustomerID],
		C.[CompanyName], 
		O.[OrderID], 
		O.[OrderDate],
		O.[RequiredDate],
		O.[ShippedDate]
FROM ([Northwind].[dbo].[Customers] AS C
INNER JOIN [Northwind].[dbo].[Orders] AS O
ON C.[CustomerID] = O.[CustomerID])

--- Membuat Procedur dan SET Customer ID sebagai Key pemanggilannya
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE INVOICE_Q
 @CustomerID VARCHAR(100)
AS
BEGIN
SET NOCOUNT ON;
SELECT * FROM NOMOR_9
WHERE CustomerID = @CustomerID
END
GO
--- EKSEKUSI CONTOH
exec INVOICE_Q 'ANTON'
