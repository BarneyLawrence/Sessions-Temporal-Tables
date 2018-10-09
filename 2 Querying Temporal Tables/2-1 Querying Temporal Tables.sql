USE TemporalTest;

--Querying a temporal table
--Building a query for each of the times we logged
SELECT
'SELECT * FROM [dbo].[MyFirstTemporalTable] FOR SYSTEM_TIME AS OF ''' + CAST(Time AS varchar(20)) + ''''
FROM dbo.timings

SELECT * FROM [dbo].[MyFirstTemporalTable] FOR SYSTEM_TIME AS OF '2018-10-07 14:45:50'
SELECT * FROM [dbo].[MyFirstTemporalTable] FOR SYSTEM_TIME AS OF '2018-10-07 14:45:52'
SELECT * FROM [dbo].[MyFirstTemporalTable] FOR SYSTEM_TIME AS OF '2018-10-07 14:45:54'
SELECT * FROM [dbo].[MyFirstTemporalTable] FOR SYSTEM_TIME AS OF '2018-10-07 14:45:56'

--But we can't get a time via a subquery
SELECT *
FROM [dbo].[MyFirstTemporalTable]
FOR SYSTEM_TIME
	AS OF (SELECT [Time] FROM dbo.timings WHERE Change = 1)


--We need a variable first
DECLARE @Time1 as datetime2(0)

SET @Time1 =  (SELECT [Time] FROM dbo.timings WHERE Change = 2)

SELECT *
FROM [dbo].[MyFirstTemporalTable]
FOR SYSTEM_TIME
	AS OF @Time1
GO

--We can use this in a table valued function
CREATE OR ALTER FUNCTION dbo.MyFirstTemporalTable_AsOfTime
(	
@AsOfTime datetime2(0)
)
RETURNS TABLE 
AS
RETURN 
(
SELECT *
FROM [dbo].[MyFirstTemporalTable]
FOR SYSTEM_TIME
	AS OF @AsOfTime
)
GO

--Like This
SELECT *
FROM dbo.MyFirstTemporalTable_AsOfTime((SELECT [Time] FROM dbo.timings WHERE Change = 2))

--Or Like this
SELECT *
FROM dbo.timings AS T
CROSS APPLY dbo.MyFirstTemporalTable_AsOfTime(T.Time)