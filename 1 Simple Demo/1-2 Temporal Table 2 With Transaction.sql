CREATE TABLE dbo.MyFirstTemporalTable2   
(    
  [Number] int NOT NULL  PRIMARY KEY CLUSTERED   
  , [Text] nvarchar(100) NOT NULL  
  , [ValidFrom] datetime2 (0) GENERATED ALWAYS AS ROW START  
  , [ValidTo] datetime2 (0) GENERATED ALWAYS AS ROW END  
  , PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)  
 )    
 WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.MyFirstTemporalTable2History));  

GO


--Insert a row
--DELETE FROM [dbo].[MyFirstTemporalTable2]
DROP TABLE IF EXISTS dbo.timings2
CREATE TABLE dbo.timings2 ([Change] int NOT NULL,[Time] datetime2(0) NOT NULL)



INSERT INTO [dbo].[MyFirstTemporalTable2]
           ([Text]
           ,[Number])
     VALUES
           ('Row 1',1),('R0w 2',2);

INSERT INTO dbo.timings2
VALUES (1,SYSUTCDATETIME())

WAITFOR DELAY '00:00:02'

BEGIN TRANSACTION

INSERT INTO [dbo].[MyFirstTemporalTable2]  ([Text] ,[Number])
     VALUES ('Row 3',3);

INSERT INTO dbo.timings2 VALUES (2,SYSUTCDATETIME())

WAITFOR DELAY '00:00:02'

UPDATE [dbo].[MyFirstTemporalTable2]
   SET [Text] = 'Row 2'
 WHERE [Number] = '2'

 INSERT INTO dbo.timings2 VALUES (3,SYSUTCDATETIME())

WAITFOR DELAY '00:00:02'

DELETE FROM [dbo].[MyFirstTemporalTable2]
WHERE [Number] = 1

INSERT INTO dbo.timings2 VALUES (4,SYSUTCDATETIME())

COMMIT TRANSACTION

SELECT *
FROM [dbo].[MyFirstTemporalTable2]
SELECT *
FROM [dbo].[MyFirstTemporalTable2History]


--Repeating updates inside a transaction

BEGIN TRANSACTION

	DECLARE @MyLoop int = 0

	WHILE @MyLoop <5

	BEGIN

        UPDATE [dbo].[MyFirstTemporalTable2]
            SET [Text] = 'Row 2'
        WHERE [Number] = '2'

        WAITFOR DELAY '00:00:01'

		 SET @MyLoop = @MyLoop + 1

	END

COMMIT TRANSACTION

--Let's look at what's in the tables again
SELECT *
FROM [dbo].[MyFirstTemporalTable2]
SELECT *
FROM [dbo].[MyFirstTemporalTable2History]

SELECT *
FROM [dbo].[MyFirstTemporalTable2]
FOR SYSTEM_TIME
	AS OF '2018-09-12 16:52:02'


--We can't do these
DROP TABLE dbo.MyFirstTemporalTable2
TRUNCATE TABLE dbo.MyFirstTemporalTable2 

GO


ALTER TABLE dbo.MyFirstTemporalTable2   
   SET (SYSTEM_VERSIONING = OFF)

--We can still insert
INSERT INTO [dbo].[MyFirstTemporalTable2]
           ([Number] ,[Text])
     VALUES
           (4, 'Row 4')
GO

--What if we change the dates?
INSERT INTO [dbo].[MyFirstTemporalTable2]
           ([Number], [Text], [ValidFrom], [ValidTo])
     VALUES
           (5, 'Row 5','2018-01-01','2018-03-31')

--Remove the period and try again
ALTER TABLE dbo.[MyFirstTemporalTable2]   
DROP PERIOD FOR SYSTEM_TIME; 

GO

INSERT INTO [dbo].[MyFirstTemporalTable2]
           ([Number], [Text], [ValidFrom], [ValidTo])
     VALUES
           (5, 'Row 5','2018-01-01','2018-03-31')

GO

DROP TABLE dbo.MyFirstTemporalTable2
DROP TABLE dbo.MyFirstTemporalTable2History