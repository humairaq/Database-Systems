USE AdventureWorks2017;


--SIMPLE 1
--Find the salesorderid, customerid, accountnumber and orderdate for all orders
--placed in the year 2014

SELECT OH.SalesOrderID,
       C.CustomerID,
       C.AccountNumber,
       OH.OrderDate
FROM Sales.Customer AS C
    INNER JOIN Sales.SalesOrderHeader AS OH
        ON C.CustomerID = OH.CustomerID
WHERE YEAR(OH.OrderDate) = 2014
ORDER BY OH.CustomerID,
         OH.OrderDate;
--FOR JSON PATH, ROOT('CustomerOrders'), INCLUDE_NULL_VALUES;

--SIMPLE 2
--Find all the customerids of customers who did not place any orders
USE AdventureWorks2017;
SELECT C.CustomerID,
       S.SalesOrderID,
       S.OrderDate
FROM Sales.Customer AS C
    LEFT OUTER JOIN Sales.SalesOrderHeader AS S
        ON C.CustomerID = S.CustomerID
WHERE S.SalesOrderID IS NULL;
--FOR JSON PATH, ROOT('NoOrders'), INCLUDE_NULL_VALUES;

--SIMPLE 3
--Find locations based on sales territories that have ip addresses beginning with 
-- '192' and include the locations country, city, state/province code, state/province name,
--country/region code and postal code
USE AdventureWorksDW2017;
SELECT T.SalesTerritoryCountry,
       G.City,
       G.StateProvinceCode,
       G.StateProvinceName,
       G.CountryRegionCode,
       G.PostalCode,
       G.IpAddressLocator
FROM dbo.DimSalesTerritory AS T
    INNER JOIN dbo.DimGeography AS G
        ON G.SalesTerritoryKey = T.SalesTerritoryKey
WHERE G.IpAddressLocator LIKE '192%';
--FOR JSON PATH, ROOT('IpAddress'), INCLUDE_NULL_VALUES;

--SIMPLE 4
--Find information about customers who placed their first purchase
--during the year of 2014, who have a postal code that starts with a letter
-- and include the customerkey, geography key, date of first purchase
--Email address, phone number, address,postal country and country 
SELECT C.CustomerKey,
       C.GeographyKey,
       CONCAT_WS(',', C.FirstName, C.LastName) AS custname,
       (C.DateFirstPurchase) AS FirstPurchase,
       C.EmailAddress,
       C.Phone,
       CONCAT_WS(' ,', C.AddressLine1, G.City, G.StateProvinceCode, G.StateProvinceName) AS Address,
       G.PostalCode AS ZipCode,
       G.EnglishCountryRegionName AS country
FROM dbo.DimCustomer AS C
    INNER JOIN dbo.DimGeography AS G
        ON G.GeographyKey = C.GeographyKey
WHERE YEAR(C.DateFirstPurchase) = 2014
      AND G.PostalCode LIKE '[A-Z]%'
ORDER BY G.EnglishCountryRegionName,
         C.CustomerKey;
--FOR JSON PATH,ROOT('CustomerLocation'),INCLUDE_NULL_VALUES;

--SIMPLE 5
--Assign loyalty levels to customers based on the amount of orders they placed 
--beginning with the most amount of orders being Platinum level then Gold, Silver and Bronze
--as decreasing levels
USE Northwinds2020TSQLV6;
SELECT DISTINCT
       C.CustomerId,
       C.CustomerContactName,
       COUNT(O.OrderId) AS Orders,
       "LoyaltyLevel" = CASE
                            WHEN COUNT(O.OrderId) >= 30 THEN
                                'Platinum'
                            WHEN COUNT(O.OrderId) < 30
                                 AND COUNT(O.OrderId) >= 20 THEN
                                'Gold'
                            WHEN COUNT(O.OrderId) < 20
                                 AND COUNT(O.OrderId) >= 10 THEN
                                'Silver'
                            WHEN COUNT(O.OrderId) < 10 THEN
                                ' Bronze'
                        END
FROM Sales.[Order] AS O
    INNER JOIN Sales.Customer AS C
        ON C.CustomerId = O.CustomerId
GROUP BY C.CustomerId,
         C.CustomerContactName
ORDER BY Orders DESC
--FOR JSON PATH, ROOT('Loyalty'), INCLUDE_NULL_VALUES;

--MEDIUM 1
--Find the amount of orders shipped by each shipping company based on the country they shipped and limit the results to shipments of amounts greater than 10
USE Northwinds2020TSQLV6;
SELECT S.ShipperCompanyName,
       COUNT(*) AS AmtShippedToCountry,
       O.ShipToCountry AS Countries
FROM Sales.Shipper AS S
    INNER JOIN Sales.[Order] AS O
        ON O.ShipperId = S.ShipperId
GROUP BY S.ShipperCompanyName,
         O.ShipToCountry
HAVING COUNT(*) > 10
ORDER BY AmtShippedToCountry DESC;
--FOR JSON PATH, ROOT('TopShipperCountries'), INCLUDE_NULL_VALUES;

--MEDIUM 2
--During the production phases of all products, which products were in the top 10 percent
-- for having the longest difference in time between their scheduled start date and actual
--start date and the longest difference in time between their scheduled end date
--and which sequence of production were they in
USE AdventureWorks2017;
SELECT TOP (10) PERCENT
       WOR.WorkOrderID,
       P.Name AS ProductName,
       L.Name AS OperationLocation,
       WOR.OperationSequence,
       DATEDIFF(dd, WOR.ScheduledStartDate, WOR.ActualStartDate) AS ScheduledVSActualStartDate,
       DATEDIFF(dd, WOR.ScheduledEndDate, WOR.ActualEndDate) AS ScheduledVSActualEndDate
FROM Production.WorkOrderRouting AS WOR
    INNER JOIN Production.Location AS L
        ON L.LocationID = WOR.LocationID
    INNER JOIN Production.Product AS P
        ON P.ProductID = WOR.ProductID
WHERE DATEDIFF(dd, WOR.ScheduledStartDate, WOR.ActualStartDate) > 0
      AND DATEDIFF(dd, WOR.ScheduledEndDate, WOR.ActualEndDate) > 0
GROUP BY DATEDIFF(dd, WOR.ScheduledStartDate, WOR.ActualStartDate),
         DATEDIFF(dd, WOR.ScheduledEndDate, WOR.ActualEndDate),
         WOR.WorkOrderID,
         P.Name,
         L.Name,
         WOR.OperationSequence
ORDER BY ScheduledVSActualEndDate DESC,
         WOR.OperationSequence,
         P.Name
--FOR JSON PATH, ROOT('ProductionTime'),INCLUDE_NULL_VALUES

--MEDIUM 3
--Find all the sales representatives by their sales territory and the country
--return their 
--base rate pay, pay frequency(whether they were payed biweekly or had a salary),
-- and calculate their total salary based on 
--their base rate pay, pay frequency, commission percent, and bonus
USE AdventureWorks2017;
SELECT Territory.Name,
       Territory.CountryRegionCode,
       E.JobTitle,
       CONCAT_WS(', ', P.FirstName, P.MiddleName, P.LastName) AS SalesPersonName,
       pay.Rate,
       "PayFrequency" = CASE
                            WHEN pay.PayFrequency = 1 THEN
                                'Salary'
                            ELSE
                                'BiWeekly'
                        END,
       ((SP.CommissionPct * SP.SalesYTD) + (pay.Rate * 40 * 14) * 26 + SP.Bonus) AS TotalSalary
FROM HumanResources.Employee AS E
    RIGHT OUTER JOIN Sales.SalesPerson AS SP
        ON E.BusinessEntityID = SP.BusinessEntityID
    INNER JOIN Person.Person AS P
        ON P.BusinessEntityID = E.BusinessEntityID
    INNER JOIN Sales.SalesTerritory AS Territory
        ON Territory.TerritoryID = SP.TerritoryID
    INNER JOIN HumanResources.EmployeePayHistory AS pay
        ON pay.BusinessEntityID = E.BusinessEntityID
GROUP BY CONCAT_WS(', ', P.FirstName, P.MiddleName, P.LastName),
         CASE
             WHEN pay.PayFrequency = 1 THEN
                 'Salary'
             ELSE
                 'BiWeekly'
         END,
         ((SP.CommissionPct * SP.SalesYTD) + (pay.Rate * 40 * 14) * 26 + SP.Bonus),
         Territory.Name,
         Territory.CountryRegionCode,
         E.JobTitle,
         pay.Rate
ORDER BY TotalSalary DESC;
--FOR JSON PATH, ROOT('SalesRepSalary'),INCLUDE_NULL_VALUES;

--medium 4
--Find all products that were scrapped based on the year and month, and include 
--the quantity that was scrapped, how much each unit costs, the calculated total scrap
--cost and the reason for scrapping the product
--return all products that had a scrap quantity greater then or equal to 10
--starting with the products that had the highest totalscrapcost

USE AdventureWorks2017;
SELECT YEAR(WO.EndDate) AS ScrapYear,
       MONTH(WO.EndDate) AS ScrapMonth,
       WO.ProductID AS ScrappedProductID,
       WO.WorkOrderID,
       P.Name,
       P.ProductNumber,
       WO.ScrappedQty,
       WOR.ActualCost,
       (WO.ScrappedQty) * (WOR.ActualCost) AS TotalScrapCost,
       SR.Name AS ScrapReason
FROM Production.WorkOrder AS WO
    INNER JOIN Production.Product AS P
        ON P.ProductID = WO.ProductID
    INNER JOIN Production.ScrapReason AS SR
        ON SR.ScrapReasonID = WO.ScrapReasonID
    INNER JOIN Production.WorkOrderRouting AS WOR
        ON WOR.WorkOrderID = WO.WorkOrderID
WHERE WO.ScrappedQty >= 10
GROUP BY YEAR(WO.EndDate),
         MONTH(WO.EndDate),
         (WO.ScrappedQty) * (WOR.ActualCost),
         WO.ProductID,
         WO.WorkOrderID,
         P.Name,
         P.ProductNumber,
         WO.ScrappedQty,
         WOR.ActualCost,
         SR.Name
ORDER BY ScrapYear,
         ScrapMonth,
         TotalScrapCost DESC;
--FOR JSON PATH, ROOT('TotalScrapCost'),INCLUDE_NULL_VALUES;

--medium 5
--Determine the growth in sales territories for internet sales
--beginning with the first order year up until the last order year 
--med1 
USE AdventureWorksDW2017;
SELECT C.OrderYear,
       C.TerritoryAmt AS CurrentTerritoryAmt,
       P.TerritoryAmt AS PreviousTerritoryAmt,
       C.TerritoryAmt - P.TerritoryAmt AS GrowthInTerritories
FROM
(
    SELECT DATEPART(yyyy, OrderDate) AS OrderYear,
           COUNT(DISTINCT SalesTerritoryKey) AS TerritoryAmt
    FROM dbo.FactInternetSales
    GROUP BY DATEPART(yyyy, OrderDate)
) AS C
    LEFT OUTER JOIN
    (
        SELECT DATEPART(yyyy, OrderDate) AS OrderYear,
               COUNT(DISTINCT SalesTerritoryKey) AS TerritoryAmt
        FROM dbo.FactInternetSales
        GROUP BY DATEPART(yyyy, OrderDate)
    ) AS P
        ON C.OrderYear = P.OrderYear + 1
--FOR JSON PATH, ROOT('TerritoryGrowth'),INCLUDE_NULL_VALUES;

--medium 6
--Determine the total amount of orders placed based upon the reason of sale
--for internet sales with the results starting from the top reason
USE AdventureWorksDW2017;
SELECT DISTINCT
       SR.SalesReasonName,
       COUNT(FIS.SalesOrderLineNumber) AS CountOrders
FROM dbo.DimSalesReason AS SR
    INNER JOIN dbo.FactInternetSalesReason AS FISR
        ON FISR.SalesReasonKey = SR.SalesReasonKey
    INNER JOIN dbo.FactInternetSales AS FIS
        ON FIS.SalesOrderNumber = FISR.SalesOrderNumber
           AND FIS.SalesOrderLineNumber = FISR.SalesOrderLineNumber
WHERE FIS.SalesOrderLineNumber >= 1
GROUP BY SR.SalesReasonName
ORDER BY CountOrders DESC
--FOR JSON PATH, ROOT('TotalOrders'), INCLUDE_NULL_VALUES;

--medium 7
--Calculate the total amount of revenue based on each territory
--according to the amount of orders placed, their unit price and discount if applicable
USE AdventureWorks2017;
SELECT C.TerritoryID,
       SUM(SOD.OrderQty * SOD.UnitPrice) - SUM((SOD.OrderQty * SOD.UnitPrice) * (1 - SOD.UnitPriceDiscount)) AS Total
FROM Sales.Customer AS C
    INNER JOIN Sales.SalesOrderHeader AS O
        ON C.CustomerID = O.CustomerID
    INNER JOIN Sales.SalesOrderDetail AS SOD
        ON O.SalesOrderID = SOD.SalesOrderID
GROUP BY C.TerritoryID
ORDER BY Total DESC
--FOR JSON PATH,ROOT('TotalSalesByTerritory'),INCLUDE_NULL_VALUES;


--medium 8
--For each product, find the maximum list price, minimum list price, average list price
--and the difference between the maximum and minimum list price 
USE AdventureWorks2017;
SELECT DISTINCT
       P.Name AS ProductName,
       MIN(PLH.ListPrice) AS MinimumListPrice,
       MAX(PLH.ListPrice) AS MaximumListPrice,
       AVG(PLH.ListPrice) AS AverageListPrice,
       MAX(PLH.ListPrice) - MIN(PLH.ListPrice) AS MaxVsMinDiff
FROM Production.Product AS P
    INNER JOIN Production.ProductListPriceHistory AS PLH
        ON PLH.ProductID = P.ProductID
GROUP BY P.Name
ORDER BY MaxVsMinDiff DESC
--FOR JSON PATH,ROOT('ListPriceInfo'),INCLUDE_NULL_VALUES;

--complex 1
--Find the amount of orders that were placed based on the color of the product and the 
--age of the customer to determine the preferences of product colors by age 
USE [AdventureWorksDW2017]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


DECLARE FUNCTION [dbo].[GetCustomerAgeForOrder]
(
	
	@BirthDate AS DATE,
	@OrderDate AS DATETIME
)
RETURNS INT
AS
BEGIN
	
	RETURN DATEDIFF(YEAR, @birthdate, @OrderDate) -
	CASE WHEN 100 * MONTH(@OrderDate) + DAY(@OrderDate)
	< 100 * MONTH(@birthdate) + DAY(@birthdate)
	THEN 1 ELSE 0
	END;

USE AdventureWorksDW2017;
SELECT DISTINCT
       dbo.GetCustomerAgeForOrder(C.BirthDate, FIS.OrderDate) AS Age,
       P.Color, 
       COUNT(*) OVER (PARTITION BY (dbo.GetCustomerAgeForOrder(C.BirthDate, FIS.OrderDate))
                                  ORDER BY P.Color)
                     AS  OverallTotalOfColorsOrdered
FROM dbo.FactInternetSales AS FIS
    INNER JOIN dbo.DimCustomer AS C
        ON C.CustomerKey = FIS.CustomerKey
    INNER JOIN dbo.DimProduct AS P
        ON P.ProductKey = FIS.ProductKey
WHERE P.Color IS NOT NULL
      AND P.Color <> 'NA'
GROUP BY dbo.GetCustomerAgeForOrder(C.BirthDate, FIS.OrderDate),
         C.CustomerKey,
         P.EnglishProductName,
         P.Color
ORDER BY Age,
         OverallTotalOfColorsOrdered DESC,
         P.Color
--FOR JSON PATH, ROOT('AgeColorPreference'),INCLUDE_NULL_VALUES;

--complex 2
--create function to calculate the difference between unitsin and unitsout
--if the difference is greater than 0 then output the status of the product as in stock
--if the difference is less than 0 then output the status of the product as not in stock
--Determine whether or not products that have a unit price greater than 1000 
--are in stock during the month of june and december for each year
USE AdventureWorksDW2017;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.UnitStock 
(
	
	@UnitsIn INT, @UnitsOut INT
)
RETURNS NVARCHAR(30)
AS
BEGIN
	
	DECLARE @Stock NVARCHAR(30)

	SELECT @Stock = CASE 
			WHEN (@UnitsIn - @UnitsOut) <= 0
			THEN  'NOT IN STOCK'
			WHEN  (@UnitsIn - @UnitsOut) > 0
			THEN  'IN STOCK'
			ELSE 'Unknown'
			END;
	RETURN @Stock;

END;
GO
USE AdventureWorksDW2017;
SELECT F.UnitCost,
       F.ProductKey,
       P.EnglishProductName,
       P.ModelName,
       DATEPART(MM, F.MovementDate) AS Month,
       DATEPART(YYYY, F.MovementDate) AS Year,
       dbo.UnitStock(F.UnitsIn, F.UnitsOut) AS Stocklevel
FROM dbo.FactProductInventory AS F
    INNER JOIN dbo.DimDate AS D
        ON D.DateKey = F.DateKey
    INNER JOIN dbo.DimProduct AS P
        ON P.ProductKey = F.ProductKey
WHERE (
          DATEPART(MM, F.MovementDate) = 6
          OR DATEPART(MM, F.MovementDate) = 12
      )
      AND (F.UnitCost > 1000)
GROUP BY DATEPART(MM, F.MovementDate),
         DATEPART(YYYY, F.MovementDate),
         dbo.UnitStock(F.UnitsIn, F.UnitsOut),
         F.UnitCost,
         F.ProductKey,
         P.EnglishProductName,
         P.ModelName
ORDER BY F.UnitCost DESC,
         Month,
         Year,
         Stocklevel;
--FOR JSON PATH,ROOT('StockLevel'),INCLUDE_NULL_VALUES;

--complex 3
--For every employee, return the organization and department they work in, 
--their job title and full name and calculate the amount of years they worked
--up until the current year
--take into account employees that have switched department or quit
USE AdventureWorks2017;
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP FUNCTION IF EXISTS dbo.YearsInDept;
GO
CREATE FUNCTION dbo.YearsInDept
(
    @EmployeeKey INT
)
RETURNS INT
AS
BEGIN

    DECLARE @Years AS INT;

    SELECT @Years = CASE
                        WHEN DH.EndDate IS NULL THEN
                            DATEDIFF(YEAR, E.HireDate, E.ModifiedDate)
                        ELSE
                            DATEDIFF(YEAR, DH.StartDate, DH.EndDate)
                    END
    FROM HumanResources.EmployeeDepartmentHistory AS DH
        INNER JOIN HumanResources.Employee AS E
            ON E.BusinessEntityID = E.BusinessEntityID
    WHERE E.BusinessEntityID = @EmployeeKey;

    RETURN @Years;
END;
GO

SELECT E.BusinessEntityID,
       D.Name,
       D.GroupName,
       E.JobTitle,
       CONCAT_WS(', ', P.FirstName, P.MiddleName, P.LastName) AS FullName,
       dbo.YearsInDept(E.BusinessEntityID) AS YearsWorked
FROM HumanResources.Employee AS E
    INNER JOIN HumanResources.EmployeeDepartmentHistory AS DH
        ON DH.BusinessEntityID = E.BusinessEntityID
    INNER JOIN Person.Person AS P
        ON P.BusinessEntityID = E.BusinessEntityID
    INNER JOIN HumanResources.Department AS D
        ON D.DepartmentID = DH.DepartmentID
GROUP BY CONCAT_WS(', ', P.FirstName, P.MiddleName, P.LastName),
         dbo.YearsInDept(E.BusinessEntityID),
         E.BusinessEntityID,
         E.JobTitle,
         DH.DepartmentID,
         D.Name,
         D.GroupName
ORDER BY E.BusinessEntityID ASC,
         YearsWorked DESC;
--FOR JSON PATH, ROOT('EmployeeYearsWorked'),INCLUDE_NULL_VALUES;

--complex 4
-- Find all products that were rejected and include the name of the product, 
--vendorid of the vendor who dealt with the product and the amount of items rejected
USE AdventureWorks2017;
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

DROP FUNCTION IF EXISTS dbo.RejectedProducts;
GO

CREATE FUNCTION dbo.RejectedProducts
(
    @productId INT
)
RETURNS DECIMAL(8, 2)
AS
BEGIN

    DECLARE @RejectedQty INT;




    SELECT @RejectedQty = POD.RejectedQty
    FROM Purchasing.PurchaseOrderDetail AS POD
    WHERE POD.ProductID = @productId
          AND POD.RejectedQty > 0;
    IF (@RejectedQty IS NULL)
        SET @RejectedQty = 0;
    RETURN @RejectedQty;


END;
GO


USE AdventureWorks2017;
SELECT PO.ProductID,
       P.Name AS ProductName,
       POH.VendorID,
       dbo.RejectedProducts(PO.ProductID) AS RejectedItems
FROM Purchasing.PurchaseOrderDetail AS PO
    INNER JOIN Purchasing.PurchaseOrderHeader AS POH
        ON POH.PurchaseOrderID = PO.PurchaseOrderID
    INNER JOIN Purchasing.Vendor AS V
        ON V.BusinessEntityID = POH.VendorID
    INNER JOIN Production.Product AS P
        ON P.ProductID = PO.ProductID
GROUP BY dbo.RejectedProducts(PO.ProductID),
         PO.ProductID,
         P.Name,
         POH.VendorID
         
ORDER BY RejectedItems DESC OFFSET 0 ROWS FETCH FIRST 100 ROWS ONLY
--FOR JSON PATH,ROOT('Reject_Products'),INCLUDE_NULL_VALUES;

--complex 5
--find the top 5 most expensive products to ship based on the ship rate
-- by the weight of the product in pounds(LB) plus the shippers base ship rate 
USE AdventureWorks2017;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP FUNCTION IF EXISTS dbo.ProductWeightLB;
GO
CREATE FUNCTION dbo.ProductWeightLB
(
    @productId INT
)
RETURNS DECIMAL(8, 2)
AS
BEGIN
    DECLARE @Weight DECIMAL(8, 2);

    SELECT @Weight = P.Weight
    FROM Production.Product AS P
    WHERE P.ProductID = @productId;

    RETURN @Weight;

END;
GO
USE AdventureWorks2017;
SELECT MAX(DISTINCT SOD.ProductID) AS ProductID,
       Ship.ShipMethodID AS ShipperId,
       Ship.Name AS ShipperName,
       (Ship.ShipBase + Ship.ShipRate * dbo.ProductWeightLb(P.ProductID)) AS ShipPrice
FROM Sales.SalesOrderHeader AS SOH
    INNER JOIN Purchasing.ShipMethod AS Ship
        ON Ship.ShipMethodID = SOH.ShipMethodID
    INNER JOIN Sales.Customer AS C
        ON C.CustomerID = SOH.CustomerID
    INNER JOIN Sales.SalesOrderDetail AS SOD
        ON SOD.SalesOrderID = SOH.SalesOrderID
    INNER JOIN Production.Product AS P
        ON P.ProductID = SOD.ProductID
WHERE P.WeightUnitMeasureCode = 'LB'
GROUP BY (Ship.ShipBase + Ship.ShipRate * dbo.ProductWeightLb(P.ProductID)),
         Ship.ShipMethodID,
         Ship.Name
ORDER BY ShipPrice DESC OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
--FOR JSON PATH,ROOT('MostExpensiveShipments'),INCLUDE_NULL_VALUES;

USE Northwinds2020TSQLV6;
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
--complex 6
--Determine whether a shipment was late, early or on time for each customer based on 
--the difference between the requireddate of the order and the ship date and include
--the customerid, amount of orders shipped to them, the shippercompany that shipped those
--orders and the customers country
CREATE FUNCTION dbo.shipTime
(
    @orderid INT,
    @requireddate DATE,
    @shiptodate DATE
)
RETURNS NVARCHAR(30)
AS
BEGIN

    DECLARE @shiptime NVARCHAR(30);


    SELECT @shiptime = CASE
                           WHEN DATEDIFF(DAY, O.RequiredDate, O.ShipToDate) < 0 THEN
                               'Late Shipment'
                           WHEN DATEDIFF(DAY, O.RequiredDate, O.ShipToDate) > 0 THEN
                               'Shipped Early'
                           ELSE
                               'ON TIME'
                       END
    FROM Sales.[Order] AS O
    WHERE O.OrderId = @orderid
          AND O.RequiredDate = @requireddate
          AND O.ShipToDate = @shiptodate;


    RETURN @shiptime;

END;
GO
USE Northwinds2020TSQLV6;
SELECT DISTINCT
       c.CustomerId,
       SUM(S.ShipperId) AS Shipments,
       S.ShipperCompanyName AS ShipperCompany,
       c.CustomerCountry,
       dbo.shipTime(O.OrderId, O.RequiredDate, O.ShipToDate) AS ShippingTime
FROM Sales.[Order] AS O
    INNER JOIN Sales.Shipper AS S
        ON S.ShipperId = O.ShipperId
    INNER JOIN Sales.Customer AS c
        ON c.CustomerId = O.CustomerId
WHERE dbo.shipTime(O.OrderId, O.RequiredDate, O.ShipToDate) IS NOT NULL
GROUP BY dbo.shipTime(O.OrderId, O.RequiredDate, O.ShipToDate),
         c.CustomerId,
         S.ShipperCompanyName,
         c.CustomerCountry
ORDER BY c.CustomerId DESC,
         Shipments DESC;
--FOR JSON PATH, ROOT('ShippingTimeStatus'), INCLUDE_NULL_VALUES;

--complex 7
--Find the top 10 with ties results for the average amount of actual expenses on 12/29/2010 
--and include the organization, department, account description and type of account 

USE AdventureWorksDW2017;
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION [dbo].SumActualAmount
(
    @accountkey INT,
    @financekey INT,
    @date INT
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @Amount FLOAT;

    SELECT @Amount = SUM(F.Amount)
    FROM dbo.FactFinance AS F
    WHERE F.AccountKey = @accountkey
          AND F.FinanceKey = @financekey
          AND F.ScenarioKey = 1
          AND F.DateKey = @date;
    IF (@Amount IS NULL)
        SET @Amount = 0;


    RETURN @Amount;
END;
GO

USE AdventureWorksDW2017;
SELECT TOP 10 WITH TIES
       F.Date AS AccountDate,
       O.OrganizationName,
       DG.DepartmentGroupName,
       AVG(dbo.SumActualAmount(F.AccountKey, F.FinanceKey, F.DateKey)) AS AvgAmount,
       A.AccountDescription AS DescOfAccount,
       A.AccountType AS AccountType
FROM dbo.FactFinance AS F
    INNER JOIN dbo.DimAccount AS A
        ON A.AccountKey = F.AccountKey
    INNER JOIN dbo.DimOrganization AS O
        ON O.OrganizationKey = F.OrganizationKey
    INNER JOIN dbo.DimDepartmentGroup AS DG
        ON DG.DepartmentGroupKey = F.DepartmentGroupKey
WHERE dbo.AvgActualAmount(F.AccountKey, F.FinanceKey, F.DateKey) > 0
      AND F.DateKey = 20101229
GROUP BY F.Date,
         O.OrganizationName,
         DG.DepartmentGroupName,
         F.FinanceKey,
         A.AccountDescription,
         A.AccountType
ORDER BY AvgAmount DESC
--FOR JSON PATH, ROOT('Top10HighestAmounts'), INCLUDE_NULL_VALUES;
