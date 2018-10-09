USE [master]
RESTORE DATABASE [TemporalTest] FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TemporalTest.bak' WITH  FILE = 3,  NOUNLOAD,  STATS = 5

GO


