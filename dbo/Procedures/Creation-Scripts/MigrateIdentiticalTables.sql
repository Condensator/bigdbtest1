SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateIdentiticalTables]  
(  
		@UserId BIGINT ,  
		@ModuleIterationStatusId BIGINT,  
		@CreatedTime DATETIMEOFFSET = NULL,  
		@DBName nvarchar(128),
		@TableNamesCsv varchar(MAX) ,
		@BatchCount BIGINT =100000,
		@ModuleName Nvarchar(max) = 'MigrateModule',
		@ProcessedRecords BIGINT OUTPUT,  
		@FailedRecords BIGINT OUTPUT   
)  
AS  
--DECLARE @UserId BIGINT;  
--DECLARE @CreatedTime DATETIMEOFFSET;  
--DECLARE @ModuleIterationStatusId BIGINT;  
--SET @UserId = 1;  
--SET @CreatedTime = SYSDATETIMEOFFSET();   
--DECLARE @DBName nvarchar(128) = 'Intermediate_RS';
--DECLARE @ModuleName Nvarchar(max) = 'MigrateModule'
--DECLARE @TableNamesCsv varchar(MAX)='StaticHistoryAsset#StaticHistoryAssets,StaticHistoryLocation#StaticHistoryLocations,StaticHistoryAssetHistory#StaticHistoryAssetHistories,StaticHistoryAssetLocationHistory#StaticHistoryAssetLocationHistories,StaticHistoryAssetValueHistory#StaticHistoryAssetValueHistories';
--DECLARE @BatchCount BIGINT = 100000;
--DECLARE @FailedRecords BIGINT;
--DECLARE @ProcessedRecords BIGINT;
--SET @ModuleIterationStatusId = 10465;  
--SELECT @ModuleIterationStatusId = IsNull(MAX(ModuleIterationStatusId),0) from stgProcessingLog;  
BEGIN
SET NOCOUNT ON;  
set XACT_ABORT ON;
CREATE TABLE #TableNames
(
	Id int identity(1,1),
	Name varchar(100),
	TargetName varchar(100),
	StagingName varchar(100)
);

SET @TableNamesCsv = Replace(@TableNamesCsv, '#', '.')
INSERT into #TableNames (Name,TargetName,StagingName) 
SELECT [Value] [TableName],TargetName = ParseName([Value], 1), StagingName =  ParseName([Value], 2) 
FROM string_split(@TableNamesCsv,',') 

DECLARE @query nvarchar(max) =''
DECLARE @TakeCount BIGINT = 0;
DECLARE @MaxId BIGINT = 0;
DECLARE @ProcessingLogId BIGINT;
DECLARE @TargetTable nvarchar(MAX) = ''
DECLARE @StagingTable nvarchar(MAX) = ''
DECLARE @ColumnNames nvarchar(MAX) = ''
DECLARE @StagingColumnNames nvarchar(MAX) = ''
DECLARE @CreateIndexQuery NVARCHAR(MAX) = ''

DECLARE @TotalNumberOfTables INT 
DECLARE @TotalNumberOfRecords INT 
SELECT @TotalNumberOfTables = COUNT(*) from #TableNames
DECLARE @Count INT = 1
SET @FailedRecords = 0;
SET @ProcessedRecords = @TotalNumberOfTables;

BEGIN TRY
	SET @query = N'ALTER DATABASE '+ QUOTENAME(DB_NAME()) + N' SET RECOVERY '+ 'SIMPLE' + N';';
	EXECUTE(@query);

	MERGE Mig_StaticTableMigrationLog AS [Target]
	USING (SELECT * FROM #TableNames) AS [Source]
	ON ([Source].TargetName = [Target].TableName)
	WHEN NOT MATCHED THEN
	INSERT (TableName, IsMigrated, CreatedById, CreatedTime)
	VALUES ([Source].TargetName, 0, 1, SYSDATETIMEOFFSET());

	WHILE @Count <= @TotalNumberOfTables
	BEGIN
	BEGIN TRANSACTION

		CREATE TABLE #ErrorLogs
		(Message     NVARCHAR(100), 
		 Type        NVARCHAR(100), 
		 EntityName  NVARCHAR(100), 
		 CreatedById BIGINT, 
		 CreatedTime DATETIMEOFFSET
		);
		
		CREATE TABLE #ProcessingLog(Id INT);

		SELECT @TargetTable = TargetName, @StagingTable = StagingName FROM #TableNames WHERE Id = @Count
		
		IF EXISTS(SELECT * FROM Mig_StaticTableMigrationLog WHERE TableName = @TargetTable AND IsMigrated = 0)
		BEGIN
			SET @CreateIndexQuery = ''
			SET @query = '';
			SELECT @query = @query + 'ALTER TABLE '+ @TargetTable +' NOCHECK CONSTRAINT ALL; '
			EXEC sp_executesql @query

			SELECT sys.tables.object_id, sys.tables.name as table_name, sys.columns.name as column_name, sys.indexes.name as index_name,sys.indexes.is_unique , sys.indexes.is_primary_key 
			INTO #IndexList
			FROM sys.tables, sys.indexes, sys.index_columns, sys.columns 
			WHERE (sys.tables.object_id = sys.indexes.object_id AND sys.tables.object_id = sys.index_columns.object_id AND sys.tables.object_id = sys.columns.object_id
			AND sys.indexes.index_id = sys.index_columns.index_id AND sys.index_columns.column_id = sys.columns.column_id) 
			AND sys.indexes.is_primary_key = 0  AND sys.tables.name IN (@TargetTable) 
	
			SELECT @CreateIndexQuery = 'CREATE ' +
			CASE WHEN is_unique = 1 THEN 'UNIQUE ' ELSE 'NON UNIQUE ' END +'NONCLUSTERED INDEX ['+ index_name +'] ON [dbo].['+table_name+'] (['+column_name+'] ASC) ' 
			FROM #IndexList

			SET @query = '';
			select @query = @query + 'DROP INDEX ' + table_name + '.' + index_name + '; ' from #IndexList
			EXEC sp_executesql @query;
		

			SET @query = 'SELECT @ColList = REPLACE(STUFF((SELECT '',[ '' + convert(nvarchar(100),COLUMN_Name) + '' ]''
						FROM '+@DBName+'.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @StagingTable
						FOR XML PATH('''')), 1, 2, ''[''), '' '', '''')'
		
			EXECUTE sp_executesql @query, N' @StagingTable nvarchar(70), @ColList nvarchar(max) OUTPUT', @StagingTable = @StagingTable , @ColList = @ColumnNames OUTPUT
			SELECT @ColumnNames = REPLACE(@ColumnNames, ',[UpdatedTime]', '');
			SELECT @ColumnNames = REPLACE(@ColumnNames, ',[UpdatedById]', '');
			SELECT @ColumnNames = REPLACE(@ColumnNames, ',[RowVersion]', '');
			SET @StagingColumnNames = REPLACE(@ColumnNames, '[CreatedById]', @UserId) 
			SET @StagingColumnNames = REPLACE(@ColumnNames, '[CreatedTime]', 'SYSDATETIMEOFFSET()') 

			SET @query = 'SELECT @NumberOfRecords =  COUNT(*) FROM ' + @DBName + '.dbo.'+ @StagingTable;
			EXECUTE sp_executesql @query, N' @NumberOfRecords BIGINT OUTPUT', @NumberOfRecords = @TotalNumberOfRecords OUTPUT
		
			SET @TakeCount = 0
			SET @MaxId = 0
			WHILE @TakeCount < @TotalNumberOfRecords
			BEGIN
				SET @query = 'SET IDENTITY_INSERT ' + @TargetTable + ' ON;'
				SET @query = @query + N'INSERT INTO '+@TargetTable+' ('+ @ColumnNames +') '
				SET @query = @query +'SELECT TOP '+ CAST(@BatchCount as nvarchar(15))+' '+ @StagingColumnNames + ' FROM ' + @DBName + '.dbo.'+ @StagingTable + ' WITH (TABLOCK) WHERE Id > ' + CAST(@MaxId as nvarchar(15)) +' ORDER BY Id; '
				SET @query = @query + 'SET IDENTITY_INSERT ' + @TargetTable + ' OFF;'
				EXEC sp_executesql @query

				SET @query = 'SELECT @MaxId = MAX(Id) FROM (SELECT TOP '+ CAST(@BatchCount as nvarchar(15))+' Id FROM ' + @DBName + '.dbo.'+ @StagingTable + ' WITH (TABLOCK) WHERE Id > ' + CAST(@MaxId as nvarchar(15)) +' ORDER BY Id) AS T; '
				EXECUTE sp_executesql @query, N' @MaxId BIGINT OUTPUT', @MaxId = @MaxId OUTPUT
				SET @TakeCount = @TakeCount + @BatchCount
			END
			INSERT INTO #ErrorLogs(Message,Type,EntityName,CreatedById,CreatedTime)  
			VALUES ('Successful', 'Information',@TargetTable, @UserId, SYSDATETIMEOFFSET())
		
		INSERT INTO stgProcessingLog(StagingRootEntityId,CreatedById,CreatedTime,ModuleIterationStatusId)  OUTPUT Inserted.Id INTO #ProcessingLog
		VALUES (0, @UserId, @CreatedTime,@ModuleIterationStatusId)
		SELECT TOP 1 @ProcessingLogId = Id FROM #ProcessingLog;
		INSERT INTO stgProcessingLogDetail(Message,Type,EntityName,CreatedById,CreatedTime,ProcessingLogId) SELECT *,@ProcessingLogId FROM #ErrorLogs

		EXEC sp_executesql @CreateIndexQuery
		SET @query=''
		SELECT @query = @query + 'ALTER TABLE ' + @TargetTable + ' WITH CHECK CHECK CONSTRAINT ALL; '
		EXEC sp_executesql @query

		UPDATE Mig_StaticTableMigrationLog SET IsMigrated = 1, UpdatedById = 1, UpdatedTime = SYSDATETIMEOFFSET()  WHERE TableName = @TargetTable

		DROP TABLE IF EXISTS #IndexList
	END
	
	SET @Count = @Count + 1

	DROP TABLE IF EXISTS #ProcessingLog
	DROP TABLE IF EXISTS #ErrorLogs

	COMMIT TRANSACTION
	END

	SET @query = N'ALTER DATABASE '+ QUOTENAME(DB_NAME()) + N' SET RECOVERY '+ 'FULL' + N';';
    EXECUTE(@query);

END TRY
BEGIN CATCH
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;

	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		SET @FailedRecords = @FailedRecords + 1
	END;  
	ELSE 
	IF (XACT_STATE()) = 1  
	BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
	END;  
	ELSE
	BEGIN
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		SET @FailedRecords = @FailedRecords + 1
	END;
END CATCH
DROP TABLE IF EXISTS #TableNames
SET NOCOUNT OFF
SET XACT_ABORT OFF
END

GO
