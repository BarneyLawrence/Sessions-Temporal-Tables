USE TemporalTest;

--Our Fact table has late entries
SELECT Count(*)
FROM dbo.Fact_TemporalSales
FOR SYSTEM_TIME AS OF '2018-04-01'
WHERE SaleDate < '2018-04-01'

SELECT Count(*)
FROM dbo.Fact_TemporalSales
FOR SYSTEM_TIME AS OF '2018-04-30'
WHERE SaleDate < '2018-04-01'


GO

--We need a function so we can feed in different dates

CREATE   FUNCTION [dbo].[Fact_TemporalSales_AsOfTime]
(	
@AsOfTime datetime2(0)
)
RETURNS TABLE 
AS
RETURN 
(
SELECT *
FROM [dbo].Fact_TemporalSales
FOR SYSTEM_TIME
	AS OF @AsOfTime
)
GO

CREATE OR ALTER VIEW dbo.Fact_TemporalSales_MarchSnapshot
AS
SELECT [RowID]
      ,[SaleDate]
      ,[SaleTime]
      ,[Quantity]
  FROM [Fact_TemporalSales_AsOfTime]('2018-04-01')

GO

CREATE OR ALTER VIEW dbo.Fact_TemporalSales_Current
AS
SELECT [RowID]
      ,[SaleDate]
      ,[SaleTime]
      ,[Quantity]
  FROM [Fact_TemporalSales]

GO

--Now put the two together

CREATE OR ALTER VIEW dbo.Fact_TemporalSales_Multiple
AS

SELECT *, 'March' AS Snapshot
FROM dbo.Fact_TemporalSales_MarchSnapshot
UNION ALL
SELECT *, 'Current' AS Snapshot
FROM dbo.Fact_TemporalSales_Current

GO

SELECT Snapshot, COUNT(*) AS SalesTotal
FROM dbo.Fact_TemporalSales_Multiple
GROUP BY Snapshot