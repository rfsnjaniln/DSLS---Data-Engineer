-- ======================================================================================
-- CASE I
-- Orderan paling banyak dikirim ke kota mana, dengan shipper apa
-- ======================================================================================
SELECT O.[ShipCity],
	S.[CompanyName],
	count (DISTINCT O.[OrderID]) as JumlahOrder,
	count (OD.[OrderID]) as TotalOrder
FROM (([Northwind].[dbo].[Shippers] AS S
	INNER JOIN [Northwind].[dbo].[Orders] AS O ON S.[ShipperID]=O.[ShipVia])
	INNER JOIN [Northwind].[dbo].[Order Details] AS OD ON O.[OrderID] = OD.[OrderID])
GROUP BY O.[ShipCity], S.[CompanyName]
ORDER BY TotalOrder DESC

-- =====================================================================================================
-- CASE II
-- menganalisis Recency, Frequency, dan 	Monetary (RFM) dalam setahun, kemudian dilakukan segmentasi 
-- dan actionable insight yang dapat dilakukan tiap segmen 
-- -- ===================================================================================================
Create View rfm_values 
AS
WITH lod as ( 
	SELECT [CustomerID], 
		[OrderDate] as last_order
	FROM (
	SELECT O.[CustomerID], 
		CAST(O.[OrderDate] AS date) AS OrderDate, 
		DENSE_RANK() over(PARTITION by O.[CustomerID] ORDER BY O.[OrderDate] DESC) as rnk_
	FROM [Northwind].[dbo].[Orders] AS O) AS lpd
	WHERE rnk_ = 1
)
, mon as (
	SELECT O.[CustomerID],
		COUNT(O.[OrderID]) AS count_trans,
		SUM(OD.Quantity) AS total_amount
	FROM [Northwind].[dbo].[Orders] AS O 
		INNER JOIN [Northwind].[dbo].[Order Details] AS OD
	ON O.OrderID = OD.OrderID
	GROUP by O.[CustomerID] )
	
SELECT mon.[CustomerID],
		CAST (lod.[last_order] AS date) AS last_order_date,
		DATEDIFF(DAY,CAST (lod.[last_order] AS date), CAST(GETDATE() AS DATE)) AS recency,
		mon.count_trans as freq,
		mon.total_amount as amount
	FROM mon
		LEFT JOIN lod
	ON lod.[CustomerID] = mon.[CustomerID];
------------------------------------------
create view rfm_class 
AS
with rfm as (
	SELECT * 
		, NTILE(4) OVER (ORDER BY recency DESC) AS R 
		, NTILE(4) OVER (ORDER BY freq DESC ) AS F 
		, NTILE(4) OVER (ORDER BY amount DESC ) AS M 
	FROM [dbo].[rfm_values]
	)
SELECT * 
	, CONCAT(R, F, M) as rfm_class
FROM rfm_class;
------------------------------------------
Create View rfm_class_end AS
	SELECT  CustomerID, rfm_class
	, CASE 
		WHEN rfm_class LIKE '1[1-2][1-2]' THEN 'Best Customers'
		WHEN rfm_class LIKE '14[1-2]' THEN 'High-spending New Customers' 
		WHEN rfm_class LIKE  '11[3-4]' THEN 'Lowest-Spending Active Loyal Customers' 
		WHEN rfm_class LIKE  '4[1-2][1-2]' THEN 'Churned Best Customers' 
		ELSE NULL 
		END AS rfm_category 
	FROM rfm_class;
--------------------------------------------
select count(CustomerID) as jumlah, rfm_category
	from rfm_class_end
	group by rfm_category 
	ORDER BY jumlah DESC

-- ======================================================================================
-- CASE III
-- Employee Analysis
-- Menganalisis siapa dan title employee yang banyak berurusan dengan order.
-- ======================================================================================
WITH Y AS (
	SELECT OD.[OrderID], 
		P.[ProductID], 
		P.[ProductName], 
		OD.[UnitPrice], 
		OD.[Quantity], 
		OD.[Discount],
		((OD.[UnitPrice] * OD.[Quantity]) - ((OD.[UnitPrice] * OD.[Quantity]) * OD.[Discount])) AS HARGA,
		E.[TitleOfCourtesy],
		E.[Title]
FROM [Northwind].[dbo].[Products] AS P
	INNER JOIN [Northwind].[dbo].[Order Details] AS OD ON P.[ProductID] = OD.[ProductID]
	INNER JOIN [Northwind].[dbo].[Orders] AS O ON OD.[OrderID] = O.[OrderID]
	INNER JOIN [Northwind].[dbo].[Employees] AS E ON  E.[EmployeeID] = O.[EmployeeID]),

membership AS (
	SELECT *,
		CASE WHEN (Y.[HARGA]) <=100 THEN 'A'
			WHEN (Y.[HARGA]) > 100 AND (Y.[HARGA]) <=250 THEN 'B'
			WHEN (Y.[HARGA]) > 250 AND (Y.[HARGA]) <=500 THEN 'C'
			ELSE 'D' END AS LABELNYA
	FROM Y)

SELECT 
		[TitleOfCourtesy],
		[Title],
	   COUNT(CASE WHEN LABELNYA = 'A' THEN LABELNYA END) AS 'Pembeli Low',
	   COUNT(CASE WHEN LABELNYA = 'B' THEN LABELNYA END) AS 'Pembeli Mid1',
	   COUNT(CASE WHEN LABELNYA = 'C' THEN LABELNYA END) AS 'Pembeli Mid2',
	   COUNT(CASE WHEN LABELNYA = 'D' THEN LABELNYA END) AS 'Pembeli High',
	   COUNT ([TitleOfCourtesy]) AS Jumlah
FROM membership
GROUP BY [TitleOfCourtesy], [Title]
ORDER BY Jumlah DESC
-- ================================================================================

