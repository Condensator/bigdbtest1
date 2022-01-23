SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[AuditTablesView]
AS
SELECT 
	 tbl.[name] AS TableName
	,CONCAT('dbo_',tbl.[name],'_CT') AS CTTableName
	,tbl.[object_id]
	,AEC.NaturalIdentifier
	,AEC.NaturalIdentifierLookupField 
	,AEC.NaturalIdentifierLookupEntity 
FROM sys.tables tbl
INNER JOIN AuditEntityConfigs AEC 
 ON tbl.[Name] = AEC.TableName AND AEC.IsActive = 1 AND AEC.IsEnabled = 1 AND tbl.is_tracked_by_cdc = 1

GO
