SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GenerateTableCreateScript]
(
	@TableName SYSNAME
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE  
	      @object_name SYSNAME  
	    , @object_id INT
		, @clustered_index SYSNAME
	    , @SQL NVARCHAR(MAX)  
	  
	SELECT  
	      @object_name = '[' + OBJECT_SCHEMA_NAME(o.[object_id]) + '].[' + OBJECT_NAME([object_id]) + ']'  
	    , @object_id = [object_id]  
	FROM (SELECT [object_id] = OBJECT_ID(@TableName, 'U')) o  
	
	IF @object_name IS NULL
		RETURN ''

	SET @SQL = 'CREATE TABLE ' + @object_name + CHAR(13) + '(' + CHAR(13) 
	+ CHAR(9) + '[Audit_Id]	BIGINT IDENTITY(1,1) NOT NULL,'  + CHAR(13) 
	+ CHAR(9) + '[Audit_TransactionLSN] BINARY(10) NOT NULL,' + CHAR(13) 
	+ CHAR(9) + '[Audit_TransactionUser] BIGINT NOT NULL,' + CHAR(13) 
	+ CHAR(9) + '[Audit_TransactionTime] DATETIMEOFFSET NOT NULL,' + CHAR(13) 
	+ CHAR(9) + '[Audit_Operation] NVARCHAR(6) NOT NULL,' + CHAR(13) 
	+ CHAR(9) + 'CONSTRAINT PK_Audit_'+ @TableName +' PRIMARY KEY NONCLUSTERED (Audit_Id)'  + CHAR(13)
	+  ');'   + CHAR(13)
	  
	SELECT @SQL = @SQL + STUFF((  
	    SELECT CHAR(13) + 'ALTER TABLE '+ @object_name +'  ADD  [' + name + '] ' +   
	        CASE WHEN is_computed = 1  
	            THEN 'AS ' + OBJECT_DEFINITION([object_id], column_id)  
	            ELSE   
	                CASE WHEN system_type_id != user_type_id   
	                    THEN '[' + SCHEMA_NAME(TypeSchemaId) + '].[' + TypeName + ']'   
	                    ELSE '[' + UPPER(TypeName) + ']'   
	                END  +   
	                CASE   
	                    WHEN TypeName IN ('varchar', 'char', 'varbinary', 'binary')  
	                        THEN '(' + CASE WHEN max_length = -1   
	                                        THEN 'MAX'   
	                                        ELSE CAST(max_length AS VARCHAR(5))   
	                                    END + ')'  
	                    WHEN TypeName IN ('nvarchar', 'nchar')  
	                        THEN '(' + CASE WHEN max_length = -1   
	                                        THEN 'MAX'   
	                                        ELSE CAST(max_length / 2 AS VARCHAR(5))   
	                                    END + ')'  
	                    WHEN TypeName IN ('datetime2', 'time2', 'datetimeoffset')   
	                        THEN '(' + CAST(scale AS VARCHAR(5)) + ')'  
	                    WHEN TypeName = 'decimal'  
	                        THEN '(' + CAST([precision] AS VARCHAR(5)) + ',' + CAST(scale AS VARCHAR(5)) + ')'  
	                    ELSE ''  
	                END +  
					IIF(name = 'Id',' NOT NULL;',' NULL;') + CHAR(13) 
	        END  
	    FROM AuditColumnsView
		WHERE [object_id] = @object_id
	    ORDER BY column_id  
	    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 0, '')
	    
		SET @clustered_index = 'Id';
		
		SELECT
		TOP 1  @clustered_index = COL_NAME(fc.parent_object_id, fc.parent_column_id)
		FROM sys.foreign_keys AS f
		INNER JOIN sys.foreign_key_columns AS fc 
		ON f.object_id = fc.constraint_object_id AND delete_referential_action = 1
		AND f.parent_object_id = OBJECT_ID(@TableName)

		IF @clustered_index != 'Id'
		BEGIN
		SET @SQL = @SQL + CHAR(13) +
		'ALTER TABLE '+ @object_name +' ALTER COLUMN [' + @clustered_index + '] BIGINT NOT NULL;' +  CHAR(13)
		END

		SET @SQL = @SQL + CHAR(13) +
		'IF COL_LENGTH(N''[dbo].[' + @TableName + ']'',''' + @clustered_index + ''') IS NOT NULL' + CHAR(13) + 'BEGIN' + CHAR(13)+ CHAR(9)+ 
		'CREATE CLUSTERED INDEX IX_CLUSTERED_' + @clustered_index + ' ON dbo.' + @TableName  + '([' + @clustered_index + '])'+ CHAR(13)+ 'END' +  CHAR(13)

	RETURN @SQL
END


GO
