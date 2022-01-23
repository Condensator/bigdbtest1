SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[ResetAllIdentity]
(@nodeNumber tinyint)
as
DECLARE @sql NVARCHAR(max)='declare @newSeed bigint;'
select @sql =  @sql + ' set @newSeed=' + Cast(MaxId + @nodeNumber as varchar(50)) + '; DBCC CHECKIDENT (''dbo.' + tableName + ''', RESEED,@newSeed);'
from Mig_LWTables where HasIdentity=1
EXEC sp_executesql @sql;

GO
