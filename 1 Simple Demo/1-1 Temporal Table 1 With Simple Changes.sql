USE TemporalTest;

--My First Temporal Table
CREATE TABLE dbo.MyFirstTemporalTable   
(    
  [Number] int NOT NULL  PRIMARY KEY CLUSTERED   
  , [Text] nvarchar(100) NOT NULL  
  , [ValidFrom] datetime2 (0) GENERATED ALWAYS AS ROW START NOT NULL
  , [ValidTo] datetime2 (0) GENERATED ALWAYS AS ROW END NOT NULL
  , PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)  
 )    
 WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.MyFirstTemporalTableHistory));  

GO

--Creating a table to hold our update times
DROP TABLE IF EXISTS dbo.timings
CREATE TABLE dbo.timings ([Change] int NOT NULL,[Time] datetime2(0) NOT NULL)

--Insert some a rows

INSERT INTO [dbo].[MyFirstTemporalTable]
           ([Text]
           ,[Number])
     VALUES
           ('Row 1',1),('R0w 2',2);

--Note the function used for the time
INSERT INTO dbo.timings
VALUES (1,SYSUTCDATETIME())

WAITFOR DELAY '00:00:01'

--Insert another row
INSERT INTO [dbo].[MyFirstTemporalTable]  ([Text] ,[Number])
     VALUES ('Row 3',3);

INSERT INTO dbo.timings VALUES (2,SYSUTCDATETIME())

WAITFOR DELAY '00:00:01'

--An update
UPDATE [dbo].[MyFirstTemporalTable]
   SET [Text] = 'Row 2'
 WHERE [Number] = '2'

 INSERT INTO dbo.timings VALUES (3,SYSUTCDATETIME())

WAITFOR DELAY '00:00:01'

--And a delete
DELETE FROM [dbo].[MyFirstTemporalTable]
WHERE [Number] = 1

INSERT INTO dbo.timings VALUES (4,SYSUTCDATETIME())


--Let's look at what's in the tables
SELECT *
FROM [dbo].[MyFirstTemporalTable]
SELECT *
FROM [dbo].[MyFirstTemporalTableHistory]

--Making the same update 5 times

DECLARE @MyLoop int = 0

WHILE @MyLoop <5

BEGIN

UPDATE [dbo].[MyFirstTemporalTable]
   SET [Text] = 'Row 2'
 WHERE [Number] = '2'

 WAITFOR DELAY '00:00:01'

 SET @MyLoop = @MyLoop + 1


END
GO

--Let's look at what's in the tables again
SELECT *
FROM [dbo].[MyFirstTemporalTable]
SELECT *
FROM [dbo].[MyFirstTemporalTableHistory]
