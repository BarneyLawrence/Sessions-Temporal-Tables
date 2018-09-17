--Creating a database to work in
--DROP DATABASE IF EXISTS TemporalTest
CREATE DATABASE TemporalTest;

GO
ALTER DATABASE [TemporalTest] SET RECOVERY SIMPLE WITH NO_WAIT
GO

USE TemporalTest;
--Setting up a table with three rows and three versions for each row.

DROP TABLE IF EXISTS dbo.MonthlyUpdates_A
CREATE TABLE dbo.MonthlyUpdates_A 
(    
  [Number] int NOT NULL  PRIMARY KEY CLUSTERED   
  , [Text] nvarchar(100) NOT NULL  
  , [ValidFrom] datetime2 (0) NOT NULL  
  , [ValidTo] datetime2 (0) NOT NULL
 )
 
 GO
 
 DROP TABLE IF EXISTS dbo.MonthlyUpdates_A_History
 CREATE TABLE dbo.MonthlyUpdates_A_History 
(    
  [Number] int NOT NULL    
  , [Text] nvarchar(100) NOT NULL  
  , [ValidFrom] datetime2 (0)  NOT NULL
  , [ValidTo] datetime2 (0) NOT NULL
 )    

GO 


INSERT INTO dbo.MonthlyUpdates_A
VALUES 
     (1,'A1 - March','2018-03-01 00:00:00','9999-12-31 23:59:59')
    ,(2,'A2 - March','2018-03-01 00:00:00','9999-12-31 23:59:59')
    ,(3,'A3 - March','2018-03-01 00:00:00','9999-12-31 23:59:59')

INSERT INTO dbo.MonthlyUpdates_A_History
VALUES 
     (1,'A1 - February','2018-02-01 00:00:00','2018-02-28 23:59:59')
    ,(2,'A2 - February','2018-02-01 00:00:00','2018-02-28 23:59:59')
    ,(3,'A3 - February','2018-02-01 00:00:00','2018-02-28 23:59:59')
    ,(1,'A1 - January','2018-01-01 00:00:00','2018-01-31 23:59:59')
    ,(2,'A2 - January','2018-01-01 00:00:00','2018-01-31 23:59:59')
    ,(3,'A3 - January','2018-01-01 00:00:00','2018-01-31 23:59:59')

ALTER TABLE dbo.MonthlyUpdates_A   
   ADD PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])   
ALTER TABLE dbo.MonthlyUpdates_A   
   SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.MonthlyUpdates_A_History, DATA_CONSISTENCY_CHECK = ON))   
;  

--And a second table as well
DROP TABLE IF EXISTS dbo.MonthlyUpdates_B
CREATE TABLE dbo.MonthlyUpdates_B
(    
  [Number] int NOT NULL  PRIMARY KEY CLUSTERED   
  , [Text] nvarchar(100) NOT NULL  
  , [ValidFrom] datetime2 (0) NOT NULL  
  , [ValidTo] datetime2 (0) NOT NULL
 )
 
 GO

 DROP TABLE IF EXISTS dbo.MonthlyUpdates_B_History
 CREATE TABLE dbo.MonthlyUpdates_B_History 
(    
  [Number] int NOT NULL    
  , [Text] nvarchar(100) NOT NULL  
  , [ValidFrom] datetime2 (0)  NOT NULL
  , [ValidTo] datetime2 (0) NOT NULL
 )    

GO 


INSERT INTO dbo.MonthlyUpdates_B
VALUES 
     (1,'B1 - March','2018-03-01 00:00:00','9999-12-31 23:59:59')
    ,(2,'B2 - March','2018-03-01 00:00:00','9999-12-31 23:59:59')
    ,(3,'B3 - March','2018-03-01 00:00:00','9999-12-31 23:59:59')

INSERT INTO dbo.MonthlyUpdates_B_History
VALUES 
     (1,'B1 - February','2018-02-01 00:00:00','2018-02-28 23:59:59')
    ,(2,'B2 - February','2018-02-01 00:00:00','2018-02-28 23:59:59')
    ,(3,'B3 - February','2018-02-01 00:00:00','2018-02-28 23:59:59')
    ,(1,'B1 - January','2018-01-01 00:00:00','2018-01-31 23:59:59')
    ,(2,'B2 - January','2018-01-01 00:00:00','2018-01-31 23:59:59')
    ,(3,'B3 - January','2018-01-01 00:00:00','2018-01-31 23:59:59')

ALTER TABLE dbo.MonthlyUpdates_B   
   ADD PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])   
ALTER TABLE dbo.MonthlyUpdates_B   
   SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.MonthlyUpdates_B_History, DATA_CONSISTENCY_CHECK = ON))   
; 

GO
--Adding a table valued function for each of the above
CREATE OR ALTER FUNCTION dbo.MonthlyUpdates_A_AsOfTime
(	
@AsOfTime datetime2(0)
)
RETURNS TABLE 
AS
RETURN 
(
SELECT *
FROM [dbo].[MonthlyUpdates_A]
FOR SYSTEM_TIME
	AS OF @AsOfTime
)
GO

CREATE OR ALTER FUNCTION dbo.MonthlyUpdates_B_AsOfTime
(	
@AsOfTime datetime2(0)
)
RETURNS TABLE 
AS
RETURN 
(
SELECT *
FROM [dbo].[MonthlyUpdates_B]
FOR SYSTEM_TIME
	AS OF @AsOfTime
)
GO

DROP  TABLE IF EXISTS dbo.ReferenceTable
DROP  TABLE IF EXISTS dbo.ReferenceTable_History

CREATE TABLE dbo.ReferenceTable
(
TeamCode varchar(10) NOT NULL PRIMARY KEY CLUSTERED
,ContractCode varchar(10) NOT NULL
)

INSERT INTO dbo.ReferenceTable
VALUES
('A1','Contract1')
,('A2','Contract1')
,('A3','Contract2')
,('A4','Contract1')
,('A5','Contract2')
,('A6','Contract3')
,('A7','Contract1')
,('A8','Contract1')
,('A9','Contract2')
,('A10','Contract3')

/*
--Code to drop tables

ALTER TABLE dbo.MyFirstTemporalTable   
   SET (SYSTEM_VERSIONING = OFF)

DROP TABLE dbo.MyFirstTemporalTable
DROP TABLE dbo.MyFirstTemporalTableHistory

ALTER TABLE dbo.MyFirstTemporalTable2   
   SET (SYSTEM_VERSIONING = OFF)

DROP TABLE dbo.MyFirstTemporalTable2
DROP TABLE dbo.MyFirstTemporalTable2History

*/