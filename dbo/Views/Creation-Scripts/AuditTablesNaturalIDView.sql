SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[AuditTablesNaturalIDView] AS
SELECT 
 A.[Table]
,A.NaturalIdColumnName
,A.ForeignKey
,A.PrimaryTable
,B.MappingColumnFK
,B.MappingTable
,ISNULL(B.NaturalId, 'Id') AS NaturalId
FROM
(	
	SELECT [TableName] AS [Table],
	'Id_NaturalId' AS NaturalIdColumnName,
	NULL AS ForeignKey,
	NULL AS PrimaryTable
	FROM AuditTablesView
	
	UNION ALL
	
	SELECT
		tab.[TableName] as [Table],
		CONCAT(col.[name], '_NaturalId') AS NaturalIdColumnName,
		col.name as [ForeignKey],
		pk_tab.name as [PrimaryTable]
	from AuditTablesView tab
	inner join sys.columns col 
	    on col.object_id = tab.object_id
	left outer join sys.foreign_key_columns fk_cols
	    on fk_cols.parent_object_id = tab.object_id
	    and fk_cols.parent_column_id = col.column_id
	left outer join sys.foreign_keys fk
	    on fk.object_id = fk_cols.constraint_object_id
	left outer join sys.tables pk_tab
	    on pk_tab.object_id = fk_cols.referenced_object_id
	left outer join sys.columns pk_col
	    on pk_col.column_id = fk_cols.referenced_column_id
	    and pk_col.object_id = fk_cols.referenced_object_id
	where fk.object_id is not null 
	 and (col.name <> 'Id' AND pk_col.name <> col.name) 
) AS A
LEFT OUTER JOIN 
(
	SELECT
	 TableName
	,IIF(COL_LENGTH(TableName, NaturalIdentifier) IS NULL OR NaturalIdentifier IS NULL
	,'Id', NaturalIdentifier) AS NaturalId
	,NULL AS MappingTable
	,NULL AS MappingColumnFK
	FROM AuditTablesView 
	WHERE NaturalIdentifierLookupEntity IS NULL OR NaturalIdentifierLookupField IS NULL
	
	UNION ALL
	
	SELECT 
	 TableName 
	,IIF(
		COL_LENGTH(TableName, NaturalIdentifierLookupField) IS NOT NULL AND
		OBJECT_ID(NaturalIdentifierLookupEntity) IS NOT NULL AND 
		COL_LENGTH(NaturalIdentifierLookupEntity, NaturalIdentifier) IS NOT NULL 
		,NaturalIdentifier, 'Id') AS NaturalId 
	,IIF(
		COL_LENGTH(TableName, NaturalIdentifierLookupField) IS NOT NULL AND
		OBJECT_ID(NaturalIdentifierLookupEntity) IS NOT NULL AND 
		COL_LENGTH(NaturalIdentifierLookupEntity, NaturalIdentifier) IS NOT NULL 
		,NaturalIdentifierLookupEntity, NULL) AS MappingTable 
	,IIF(
		COL_LENGTH(TableName, NaturalIdentifierLookupField) IS NOT NULL AND
		OBJECT_ID(NaturalIdentifierLookupEntity) IS NOT NULL AND 
		COL_LENGTH(NaturalIdentifierLookupEntity, NaturalIdentifier) IS NOT NULL 
		,NaturalIdentifierLookupField, NULL) AS MappingColumnFK
	FROM AuditTablesView 
	WHERE NaturalIdentifierLookupEntity IS NOT NULL AND NaturalIdentifierLookupField IS NOT NULL
) B
ON B.[TableName] = ISNULL(A.PrimaryTable, A.[Table])

GO
