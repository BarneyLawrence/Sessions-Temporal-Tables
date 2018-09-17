USE TemporalTest

SET STATISTICS IO,TIME ON


--A Straight Select
SELECT count(*)
FROM [dbo].[Fact_TemporalSales_Big]

--With a date after all changes
SELECT count(*)
FROM [dbo].[Fact_TemporalSales_Big]
FOR SYSTEM_TIME AS OF '2099-01-01'

--With a date between changes
SELECT count(*)
FROM [dbo].[Fact_TemporalSales_Big]
FOR SYSTEM_TIME AS OF '2018-01-01'

--Duplicating with a columnstore index on the history
SELECT count(*)
FROM [dbo].[Fact_TemporalSales2_Big]
FOR SYSTEM_TIME AS OF '2018-01-01'

--What if we're selective on the RowID?
SELECT count(*)
FROM [dbo].[Fact_TemporalSales_Big]
FOR SYSTEM_TIME AS OF '2018-01-01'
WHERE RowID < 100

SELECT count(*)
FROM [dbo].[Fact_TemporalSales2_Big]
FOR SYSTEM_TIME AS OF '2018-01-01'
WHERE RowID < 100

--Looking at all rows
SELECT count(*)
FROM [dbo].[Fact_TemporalSales_Big]
FOR SYSTEM_TIME ALL
WHERE RowID < 100

SELECT count(*)
FROM [dbo].[Fact_TemporalSales2_Big]
FOR SYSTEM_TIME ALL
WHERE RowID < 100

SET STATISTICS IO,TIME OFF