USE TemporalTest

--Creating a sequence so we don't have to fuss with identiy columns
/*
--Hiding these if needed - IF EXISTS doesn't extend to the table itself not existing
ALTER TABLE dbo.Fact_TemporalSales_Big  DROP CONSTRAINT IF EXISTS DF_Fact_TemporalSales_Big_FactSequence
ALTER TABLE dbo.Fact_TemporalSales2_Big  DROP CONSTRAINT IF EXISTS DF_Fact_TemporalSales2_Big_FactSequence
ALTER TABLE dbo.Fact_Sales_Big  DROP CONSTRAINT IF EXISTS DF_Fact_Sales_Big_FactSequence
ALTER TABLE dbo.Staging_Sales_Big  DROP CONSTRAINT IF EXISTS DF_Staging_Sales_Big_FactSequence
*/

DROP SEQUENCE IF EXISTS dbo.FactSequence

CREATE SEQUENCE dbo.FactSequence  AS int
    START WITH 1  
    INCREMENT BY 1 ; 

IF EXISTS(
SELECT *
FROM sys.tables
where name = 'Fact_TemporalSales_Big'
AND temporal_type_desc = 'SYSTEM_VERSIONED_TEMPORAL_TABLE'
)
ALTER TABLE dbo.Fact_TemporalSales_Big   
   SET (SYSTEM_VERSIONING = OFF);

DROP TABLE IF EXISTS dbo.Fact_TemporalSales_Big

CREATE TABLE dbo.Fact_TemporalSales_Big
(
RowID int  NOT NULL PRIMARY KEY CLUSTERED constraint DF_Fact_TemporalSales_Big_FactSequence default next value for dbo.FactSequence
,SaleDate date NOT NULL
,SaleTime time(0) NOT NULL
,Quantity int NOT NULL
,ValidFrom datetime2(0)  NOT NULL
,ValidTo datetime2(0) NOT NULL
)
WITH (DATA_COMPRESSION = PAGE)

GO

DROP TABLE IF EXISTS dbo.Fact_TemporalSales_Big_History
CREATE TABLE dbo.Fact_TemporalSales_Big_History(
RowID int NOT NULL
,SaleDate date NOT NULL
,SaleTime time(0) NOT NULL
,Quantity int NOT NULL
,ValidFrom datetime2(0)  NOT NULL
,ValidTo datetime2(0) NOT NULL
) 

CREATE CLUSTERED INDEX [ix_Fact_TemporalSales_Big_History] ON [dbo].[Fact_TemporalSales_Big_History]
(
	[ValidTo] ASC,
	[ValidFrom] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, DATA_COMPRESSION = PAGE) ON [PRIMARY]
GO


DECLARE @RowCount int = 10000000;
DECLARE @StartDate date = '2017-04-01';
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

INSERT INTO dbo.Fact_TemporalSales_Big (SaleDate, SaleTime, Quantity, ValidFrom,ValidTo)

SELECT 
    cast(dateadd(day,R.RDateRange,@StartDate) as date) AS SaleDate
   ,cast(dateadd(second,RTime,'1900-01-01') as time(0)) AS SaleTime
   ,RQuantity AS Quantity
   ,dateadd(day, R.RDateOffset + 1,(dateadd(day,R.RDateRange,@StartDate)))  AS ValidFrom
   , CAST('9999-12-31 23:59:59' as datetime2(0)) AS ValidTo
FROM Randoms AS R

GO

--Creating some updates
WITH A AS 
(
SELECT *,  (ABS(CHECKSUM(NewId())) % 100)  AS RandomFilter
,  (ABS(CHECKSUM(NewId())) % 100)  AS RandomFilter2
,ABS(CHECKSUM(NewId())) % 10 AS NewOffset
FROM dbo.Fact_TemporalSales_Big
)
UPDATE A
SET Quantity = RandomFilter2
    ,ValidFrom = dateadd(day,ABS(CHECKSUM(NewId())) % 10,ValidFrom)
OUTPUT deleted.[RowID], deleted.[SaleDate], deleted.[SaleTime], deleted.[Quantity], deleted.[ValidFrom]
, inserted.ValidFrom
INTO dbo.Fact_TemporalSales_Big_History
WHERE RandomFilter < 5

GO

--Randomly creating deletes
WITH A AS 
(
SELECT *,  (ABS(CHECKSUM(NewId())) % 100)  AS RandomFilter
FROM dbo.Fact_TemporalSales_Big
)
DELETE FROM A
OUTPUT deleted.[RowID], deleted.[SaleDate], deleted.[SaleTime], deleted.[Quantity], deleted.[ValidFrom]
, dateadd(day,ABS(CHECKSUM(NewId())) % 10,deleted.ValidFrom)
INTO dbo.Fact_TemporalSales_Big_History
WHERE RandomFilter < 5

--Convert to a Temporal Table
ALTER TABLE dbo.Fact_TemporalSales_Big 
ADD PERIOD FOR SYSTEM_TIME(ValidFrom, ValidTo)

ALTER TABLE dbo.Fact_TemporalSales_Big   
   SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.Fact_TemporalSales_Big_History, DATA_CONSISTENCY_CHECK = ON)) 

--Making a second for comparisons

IF EXISTS(
SELECT *
FROM sys.tables
where name = 'Fact_TemporalSales2_Big'
AND temporal_type_desc = 'SYSTEM_VERSIONED_TEMPORAL_TABLE'
)
ALTER TABLE dbo.Fact_TemporalSales2_Big   
   SET (SYSTEM_VERSIONING = OFF);

DROP TABLE IF EXISTS dbo.Fact_TemporalSales2_Big

CREATE TABLE dbo.Fact_TemporalSales2_Big
(
RowID int NOT NULL PRIMARY KEY CLUSTERED constraint DF_Fact_TemporalSales2_Big_FactSequence default next value for dbo.FactSequence
,SaleDate date NOT NULL
,SaleTime time(0) NOT NULL
,Quantity int NOT NULL
,ValidFrom datetime2(0)  NOT NULL
,ValidTo datetime2(0) NOT NULL
)
WITH (DATA_COMPRESSION = PAGE)
GO

DROP TABLE IF EXISTS dbo.Fact_TemporalSales2_Big_History
CREATE TABLE dbo.Fact_TemporalSales2_Big_History(
RowID int NOT NULL
,SaleDate date NOT NULL
,SaleTime time(0) NOT NULL
,Quantity int NOT NULL
,ValidFrom datetime2(0)  NOT NULL
,ValidTo datetime2(0) NOT NULL
) 
GO

INSERT INTO dbo.Fact_TemporalSales2_Big ([RowID], [SaleDate], [SaleTime], [Quantity], [ValidFrom], [ValidTo])
SELECT * FROM dbo.Fact_TemporalSales_Big


INSERT INTO dbo.Fact_TemporalSales2_Big_History
SELECT * FROM dbo.Fact_TemporalSales_Big_History

CREATE CLUSTERED COLUMNSTORE INDEX CCI_Fact_TemporalSales_Big_History ON [dbo].[Fact_TemporalSales2_Big_History] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)

--Convert to a Temporal Table
ALTER TABLE dbo.Fact_TemporalSales2_Big 
ADD PERIOD FOR SYSTEM_TIME(ValidFrom, ValidTo)

ALTER TABLE dbo.Fact_TemporalSales2_Big   
   SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.Fact_TemporalSales2_Big_History, DATA_CONSISTENCY_CHECK = ON)) 

 --Making a not temporal copy for comparison

DROP TABLE IF EXISTS [dbo].[Fact_Sales_Big]

CREATE TABLE dbo.Fact_Sales_Big
(
RowID int NOT NULL PRIMARY KEY CLUSTERED constraint DF_Fact_Sales_Big_FactSequence default next value for dbo.FactSequence
,SaleDate date NOT NULL
,SaleTime time(0) NOT NULL
,Quantity int NOT NULL
)
WITH (DATA_COMPRESSION = PAGE)


INSERT INTO dbo.Fact_Sales_Big ([RowID], [SaleDate], [SaleTime], [Quantity])
SELECT [RowID], [SaleDate], [SaleTime], [Quantity]
FROM [dbo].[Fact_TemporalSales_Big]


--Once more for a type 2 style table

DROP TABLE IF EXISTS dbo.Fact_Type2Sales_Big

CREATE TABLE dbo.Fact_Type2Sales_Big
(
RowID_sk int IDENTITY NOT NULL
,RowID int
,SaleDate date NOT NULL
,SaleTime time(0) NOT NULL
,Quantity int NOT NULL
,ValidFrom datetime2(0)  NOT NULL
,ValidTo datetime2(0) NOT NULL
)

GO

CREATE UNIQUE CLUSTERED INDEX IX_Fact_Type2Sales_Big_RowID_Dates ON dbo.Fact_Type2Sales_Big
(
RowID
,ValidTo
,ValidFrom
)
WITH (DATA_COMPRESSION = Page)

INSERT INTO dbo.Fact_Type2Sales_Big
SELECT * FROM dbo.Fact_TemporalSales_Big
FOR SYSTEM_TIME ALL



--And again for a staging table

DROP TABLE IF EXISTS [dbo].[Staging_Sales_Big]

CREATE TABLE dbo.[Staging_Sales_Big]
(
RowID int NOT NULL PRIMARY KEY CLUSTERED constraint DF_Staging_Sales_Big_FactSequence default next value for dbo.FactSequence
,SaleDate date NOT NULL
,SaleTime time(0) NOT NULL
,Quantity int NOT NULL
)
WITH (DATA_COMPRESSION = PAGE)


INSERT INTO dbo.[Staging_Sales_Big] ([RowID], [SaleDate], [SaleTime], [Quantity])
SELECT [RowID], [SaleDate], [SaleTime], [Quantity]
FROM [dbo].[Fact_TemporalSales_Big];





--Randomly creating deletes
WITH A AS 
(
SELECT *,  (ABS(CHECKSUM(NewId())) % 100)  AS RandomFilter
FROM dbo.[Staging_Sales_Big]
)
DELETE FROM A
WHERE RandomFilter < 3;

--Creating some updates
WITH A AS 
(
SELECT *,  (ABS(CHECKSUM(NewId())) % 100)  AS RandomFilter
,  (ABS(CHECKSUM(NewId())) % 100)  AS RandomFilter2
FROM dbo.[Staging_Sales_Big]
)
UPDATE A
SET Quantity = RandomFilter2
WHERE RandomFilter < 5


DECLARE @RowCount2 int = 500000;
DECLARE @StartDate2 date = '2017-04-01';
DECLARE @EndDate2 date = '2018-03-31';
DECLARE @QuantityMax2 int = 100;

With N AS
(SELECT N.n
FROM (
VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) AS N(N)
),
Tally AS
(
SELECT TOP (@RowCount2)
Row_number() OVER(ORDER BY (SELECT NULL)) AS N
FROM N AS N1, N AS N2, N AS N3,N AS N4,N AS N5,N AS N6,N AS N7,N AS N8,N AS N9,N AS N10,N AS N11
),
Randoms AS
(
SELECT 
    ABS(CHECKSUM(NewId())) % @QuantityMax2 AS RQuantity
   ,ABS(CHECKSUM(NewId())) % (DateDiff(Day,@StartDate2,@EndDate2) + 1) AS RDateRange
   ,ABS(CHECKSUM(NewId())) % (60*60*24) AS RTime
   ,ABS(CHECKSUM(NewId())) % (7) AS RDateOffset
FROM Tally
)

INSERT INTO dbo.Staging_Sales_Big (SaleDate, SaleTime, Quantity)

SELECT 
    cast(dateadd(day,R.RDateRange,@StartDate2) as date) AS SaleDate
   ,cast(dateadd(second,RTime,'1900-01-01') as time(0)) AS SaleTime
   ,RQuantity AS Quantity
FROM Randoms AS R

