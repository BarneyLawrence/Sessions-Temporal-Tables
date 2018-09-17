USE TemporalTest

--SELECT * FROM dbo.Staging_Sales_Big

DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

SET STATISTICS IO,TIME ON;

MERGE [dbo].[Fact_TemporalSales_Big] AS target
USING [dbo].[Staging_Sales_Big] AS source
ON (target.RowID = source.RowID)
WHEN MATCHED AND EXISTS
(SELECT  target.[SaleDate], target.[SaleTime], target.[Quantity]
EXCEPT
SELECT  source.[SaleDate], source.[SaleTime], source.[Quantity]
)
THEN UPDATE SET
      
      [SaleDate] = source.[SaleDate]
    , [SaleTime] = source.[SaleTime]
    , [Quantity] = source.[Quantity]
WHEN NOT MATCHED BY TARGET
THEN INSERT ([RowID],[SaleDate], [SaleTime], [Quantity])
VALUES (source.[RowID],source.[SaleDate], source.[SaleTime], source.[Quantity])
WHEN NOT MATCHED BY SOURCE
THEN DELETE;

SET STATISTICS IO,TIME OFF;