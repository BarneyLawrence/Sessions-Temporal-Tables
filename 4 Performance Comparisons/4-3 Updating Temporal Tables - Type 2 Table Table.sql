USE TemporalTest

--SELECT * FROM dbo.Staging_Sales_Big

DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

SET STATISTICS IO,TIME ON;

WITH CurrentRows AS
(
SELECT *
FROM dbo.Fact_Type2Sales_Big
WHERE ValidTo = CAST('9999-12-31 23:59:59' as datetime2(0))
)
INSERT INTO dbo.Fact_Type2Sales_Big
(
RowID
,SaleDate
,SaleTime
,Quantity
,ValidFrom
,ValidTo
)
SELECT 
RowID
,SaleDate
,SaleTime
,Quantity
,SYSUTCDATETIME() AS ValidFrom
,CAST('9999-12-31 23:59:59' as datetime2(0)) AS ValidTo
FROM
(
MERGE CurrentRows AS target
USING [dbo].[Staging_Sales_Big] AS source
ON (target.RowID = source.RowID)
WHEN MATCHED AND EXISTS
    (SELECT  target.[SaleDate], target.[SaleTime], target.[Quantity]
    EXCEPT
    SELECT  source.[SaleDate], source.[SaleTime], source.[Quantity]
    )
THEN UPDATE SET
    ValidTo = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET
THEN 
    INSERT ([RowID],[SaleDate], [SaleTime], [Quantity],[ValidFrom],[ValidTo])
    VALUES (source.RowID,source.[SaleDate], source.[SaleTime], source.[Quantity],SYSUTCDATETIME(),'9999-12-31 23:59:59')
WHEN NOT MATCHED BY SOURCE
THEN UPDATE SET
ValidTo = SYSUTCDATETIME()

  OUTPUT $action, 
    source.[RowID], 
    source.[SaleDate],
    source.[SaleTime],
    source.[Quantity]
    

) AS MergeOut
(action
,RowID
,SaleDate
,SaleTime
,Quantity
)
WHERE action = 'UPDATE'
AND RowID IS NOT NULL
;

SET STATISTICS IO,TIME OFF;