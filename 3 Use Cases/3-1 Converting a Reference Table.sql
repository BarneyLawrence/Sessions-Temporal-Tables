USE TemporalTest;

--Here's a simple reference table mapping teams to contracts
SELECT *
FROM  dbo.ReferenceTable

--Add our date range columns note we're using the Hidden key word
ALTER TABLE  dbo.ReferenceTable
    ADD ValidFrom datetime2(0) GENERATED ALWAYS AS ROW START HIDDEN
        DEFAULT CAST('1900-01-01' as datetime2(0))
    ,ValidTo datetime2(0) GENERATED ALWAYS AS ROW END HIDDEN 
        DEFAULT CAST('9999-12-31 23:59:59' as datetime2(0))
    ,PERIOD FOR SYSTEM_TIME (ValidFrom,ValidTo)

ALTER TABLE dbo.ReferenceTable   
   SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ReferenceTable_History, DATA_CONSISTENCY_CHECK = ON)) 


--SELECT * - No Dates
SELECT *
FROM  dbo.ReferenceTable

--Because they're hidden unless given explicitly
SELECT *, ValidFrom, ValidTo
FROM  dbo.ReferenceTable

--Now some updates to test

Update dbo.ReferenceTable
SET ContractCode = 'Contract4'
WHERE TeamCode IN ('A1','A3','A4')

DELETE FROM dbo.ReferenceTable
WHERE TeamCode = 'A10'

SELECT * FROM dbo.ReferenceTable_History