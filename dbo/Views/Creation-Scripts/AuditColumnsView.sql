SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[AuditColumnsView]
AS
	SELECT 
		 ATV.TableName
		,col.[name] 
		,typ.[name] TypeName
		,typ.[schema_id] TypeSchemaId
		,col.is_computed
		,col.[object_id]
		,col.column_id
		,col.max_length
		,col.[precision]
		,col.scale
		,col.system_type_id
		,col.user_type_id  
	FROM  AuditTablesView ATV
	 JOIN sys.columns col WITH(NOLOCK) ON  ATV.[object_id] = col.[object_id] 
	 JOIN sys.types typ WITH(NOLOCK) ON col.user_type_id = typ.user_type_id  
	WHERE  
		 col.[name] NOT IN ('CreatedById', 'UpdatedById', 'CreatedTime','UpdatedTime', 'RowVersion') 
	 AND typ.[name] <> 'varbinary' 
	 AND col.[name] NOT LIKE '%[_]Source' 
	 AND col.[name] NOT LIKE '%[_]Type'

GO
