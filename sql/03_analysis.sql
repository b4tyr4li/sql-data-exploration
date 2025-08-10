USE northwind;
GO

--1. Monthly Revenue Trend
SELECT 
	CONCAT(YEAR(o.OrderDate),'-',RIGHT('0'+CAST(MONTH(o.OrderDate)AS VARCHAR),2)) AS [YearMonth],
	ROUND(SUM(od.UnitPrice*od.Quantity*(1 - od.Discount)),2) AS Revenue
FROM Orders o
JOIN [Order Details] od ON od.OrderID=o.OrderID
GROUP BY CONCAT(YEAR(o.OrderDate),'-',RIGHT('0'+CAST(MONTH(o.OrderDate)AS VARCHAR),2)) 
ORDER BY [YearMonth];


--2. Top Customers by Lifetime Value
SELECT TOP 10 
	c.CompanyName, 
	ROUND(SUM(od.UnitPrice*od.Quantity*(1 - od.Discount)),2) AS Revenue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.CompanyName
ORDER BY Revenue DESC;

--3. Category Revenue Share
SELECT 
	ct.CategoryName,
	ROUND(SUM(od.UnitPrice*od.Quantity*(1-od.Discount)),2) AS Revenue
FROM Categories ct
JOIN Products p ON p.CategoryID = ct.CategoryID
JOIN [Order Details] od ON p.ProductID = od.ProductID
GROUP BY CategoryName
ORDER BY ROUND(SUM(od.UnitPrice*od.Quantity*(1-od.Discount)),2) DESC;


--4. Repeat vs Single-Order Customers
WITH Counts AS (
	SELECT 
		CustomerID,
		Count(OrderID) AS CountForEach
	FROM Orders
	GROUP BY CustomerID
)
SELECT 
	SUM(CASE WHEN CountForEach = 1 THEN 1 ELSE 0 END) AS [Only 1 order],
	SUM(CASE WHEN CountForEach > 1 THEN 1 ELSE 0 END) AS [More than 1 order]
FROM Counts;


--5. Average Order Value (AOV) by Country
SELECT 
	c.Country,
	SUM(od.UnitPrice*od.Quantity*(1-od.Discount))/COUNT(od.OrderID) AS AOV
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.Country;


--6. Average Days to Ship
SELECT 
	c.Country,
	AVG(DATEDIFF(DAY,o.OrderDate,o.ShippedDate)) AS [Average Ship Days]
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE o.ShippedDate IS NOT NULL
GROUP BY c.Country
ORDER BY [Average Ship Days];


--7. Top Products by Sales
SELECT TOP 10
	p.ProductName AS [Name],
	SUM(od.Quantity) AS [Units Sold],
	ROUND(SUM(od.UnitPrice*od.Quantity*(1-od.Discount))/COUNT(od.OrderID),2) AS Revenue
FROM Products p
JOIN [Order Details] od ON p.ProductID = od.ProductID
GROUP BY p.ProductName
ORDER BY Revenue;


--8. Employee Sales Leaderboard
SELECT
	(e.LastName + ',' + e.FirstName) AS Employee,
	SUM(od.Quantity) AS [Number of sales],
	ROUND(SUM(od.UnitPrice*od.Quantity*(1-od.Discount))/COUNT(od.OrderID),2) AS Revenue
FROM Employees e
JOIN Orders o ON o.EmployeeID = e.EmployeeID
JOIN [Order Details] od ON od.OrderID = o.OrderID
GROUP BY e.LastName, FirstName
ORDER BY Revenue DESC;


--9. Customer Cohort Revenue
WITH Firsts AS (
  SELECT CustomerID, FORMAT(MIN(OrderDate), 'yyyy-MM') AS Cohort
  FROM Orders GROUP BY CustomerID
),
Sales AS (
  SELECT o.CustomerID,
         FORMAT(o.OrderDate, 'yyyy-MM') AS YearMonth,
         SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) AS Revenue
  FROM Orders o
  JOIN [Order Details] od ON od.OrderID = o.OrderID
  GROUP BY o.CustomerID, FORMAT(o.OrderDate, 'yyyy-MM')
)
SELECT f.Cohort, s.YearMonth, ROUND(SUM(s.Revenue), 2) AS CohortRevenue
FROM Firsts f
JOIN Sales s ON s.CustomerID = f.CustomerID
GROUP BY f.Cohort, s.YearMonth
ORDER BY f.Cohort, s.YearMonth;


--10. Discount Impact
SELECT
	CASE WHEN od.Discount>0 THEN 'Discounted' ELSE 'Full Price' END AS PriceTypes,
	ROUND(SUM(od.UnitPrice*od.Quantity*(1-od.Discount)),2) AS Revenue,
	COUNT(*) AS Lines
FROM [Order Details] od
GROUP BY CASE WHEN od.Discount>0 THEN 'Discounted' ELSE 'Full Price' END;


--11. Low-Stock Fast Sellers
SELECT
	p.ProductName,
	p.UnitsInStock,
	SUM(od.Quantity) AS [Total Units Sold]
FROM Products p
JOIN [Order Details] od ON p.ProductID = od.ProductID
GROUP BY p.ProductName,p.UnitsInStock
HAVING p.UnitsInStock<20
ORDER BY [Total Units Sold] DESC;


--12. Top Shipping Countries
SELECT
	o.ShipCountry AS Country,
	SUM(o.OrderID) AS [Number of Orders]
FROM Orders o
GROUP BY o.ShipCountry
ORDER BY [Number of Orders] DESC;

