SELECT *
FROM dbo.MonthlyUpdates_A
FOR SYSTEM_TIME ALL
ORDER BY ValidFrom

--A simple join
SELECT A.Number, A.Text AS Text_A, B.Text AS Text_B
FROM dbo.MonthlyUpdates_A AS A
INNER JOIN dbo.MonthlyUpdates_B AS B
    ON A.Number = B.Number
--FOR SYSTEM_TIME AS OF '2018-01-01' 

--This is set per table
SELECT A.Number, A.Text AS Text_A, B.Text AS Text_B
FROM dbo.MonthlyUpdates_A FOR SYSTEM_TIME AS OF '2018-01-01'  AS A
INNER JOIN dbo.MonthlyUpdates_B FOR SYSTEM_TIME AS OF '2018-02-01' AS B
    ON A.Number = B.Number;

 --This doesn't work
With AB AS
(
SELECT A.Number, A.Text AS Text_A, B.Text AS Text_B
FROM dbo.MonthlyUpdates_A AS A
INNER JOIN dbo.MonthlyUpdates_B AS B
    ON A.Number = B.Number
) 
SELECT *
FROM AB
FOR SYSTEM_TIME AS OF '2018-01-01' 
GO
--But if we create a view
CREATE OR ALTER VIEW dbo.MonthlyUpdates_AandB 
AS
SELECT A.Number, A.Text AS Text_A, B.Text AS Text_B
FROM dbo.MonthlyUpdates_A AS A
INNER JOIN dbo.MonthlyUpdates_B AS B
    ON A.Number = B.Number

GO
--It works
SELECT *
FROM dbo.MonthlyUpdates_AandB 
FOR SYSTEM_TIME AS OF '2018-02-01' 

--Even if we use it twice
SELECT *
FROM dbo.MonthlyUpdates_AandB FOR SYSTEM_TIME AS OF '2018-02-01' AS A
INNER JOIN dbo.MonthlyUpdates_AandB FOR SYSTEM_TIME AS OF '2018-03-01' AS B
    ON A.Number = B.Number
GO

--We can specify the date inside the view
CREATE OR ALTER VIEW dbo.MonthlyUpdates_AandB_January 
AS
SELECT A.Number, A.Text AS Text_A, B.Text AS Text_B
FROM dbo.MonthlyUpdates_A FOR SYSTEM_TIME AS OF '2018-01-01'  AS A
INNER JOIN dbo.MonthlyUpdates_B FOR SYSTEM_TIME AS OF '2018-01-01' AS B
    ON A.Number = B.Number;

GO

--But can't then override it
SELECT *
FROM dbo.MonthlyUpdates_AandB_January 
FOR SYSTEM_TIME AS OF '2018-02-01' 
GO

--A view with only one table with SYSTEM_TIME defined
CREATE OR ALTER VIEW dbo.MonthlyUpdates_AandB_January2 
AS
SELECT A.Number, A.Text AS Text_A, B.Text AS Text_B
FROM dbo.MonthlyUpdates_A AS A
INNER JOIN dbo.MonthlyUpdates_B FOR SYSTEM_TIME AS OF '2018-01-01' AS B
    ON A.Number = B.Number;

GO

--Nope
SELECT *
FROM dbo.MonthlyUpdates_AandB_January2 
FOR SYSTEM_TIME AS OF '2018-02-01' 
GO
--
--Or using a table values function?
CREATE OR ALTER VIEW dbo.MonthlyUpdates_AandB_January3
AS
SELECT A.Number, A.Text AS Text_A, B.Text AS Text_B
FROM dbo.MonthlyUpdates_A_AsOfTime('2018-01-01')  AS A
INNER JOIN dbo.MonthlyUpdates_B AS B
    ON A.Number = B.Number;

GO

--Still Nope
SELECT *
FROM dbo.MonthlyUpdates_AandB_January3
FOR SYSTEM_TIME AS OF '2018-02-01' 
GO