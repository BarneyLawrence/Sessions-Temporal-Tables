USE TemporalTest

DROP TABLE IF EXISTS dbo.Fact_TemporalSales

CREATE TABLE dbo.Fact_TemporalSales
(
RowID int IDENTITY NOT NULL PRIMARY KEY CLUSTERED
,SaleDate date NOT NULL
,SaleTime time(0) NOT NULL
,Quantity int NOT NULL
,ValidFrom datetime2(0)  NOT NULL
,ValidTo datetime2(0) NOT NULL
)

DECLARE @RowCount int = 10000;
DECLARE @StartDate date = '2018-01-01';
DECLARE @EndDate date = '2018-03-31';
DECLARE @QuantityMax int = 100;

With N AS
(SELECT N.n
FROM (
VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) AS N(N)
),
Tally AS
(
SELECT TOP (@RowCount)
Row_number() OVER(ORDER BY (SELECT NULL)) AS N
FROM N AS N1, N AS N2, N AS N3,N AS N4,N AS N5,N AS N6,N AS N7,N AS N8,N AS N9,N AS N10,N AS N11
),
Randoms AS
(
SELECT 
    ABS(CHECKSUM(NewId())) % @QuantityMax AS RQuantity
   ,ABS(CHECKSUM(NewId())) % (DateDiff(Day,@StartDate,@EndDate) + 1) AS RDateRange
   ,ABS(CHECKSUM(NewId())) % (60*60*24) AS RTime
   ,ABS(CHECKSUM(NewId())) % (7) AS RDateOffset
FROM Tally
)

INSERT INTO dbo.Fact_TemporalSales (SaleDate, SaleTime, Quantity, ValidFrom,ValidTo)

SELECT 
    cast(dateadd(day,R.RDateRange,@StartDate) as date) AS SaleDate
   ,cast(dateadd(second,RTime,'1900-01-01') as time(0)) AS SaleTime
   ,RQuantity AS Quantity
   ,dateadd(day, R.RDateOffset + 1,(dateadd(day,R.RDateRange,@StartDate)))  AS ValidFrom
   , CAST('9999-12-31 23:59:59' as datetime2(0)) AS ValidTo
FROM Randoms AS R

GO

--Convert to a Temporal Table

ALTER TABLE dbo.Fact_TemporalSales 
ADD PERIOD FOR SYSTEM_TIME(ValidFrom, ValidTo)

ALTER TABLE dbo.Fact_TemporalSales   
   SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.Fact_TemporalSales_History, DATA_CONSISTENCY_CHECK = ON)) 
