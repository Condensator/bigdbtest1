SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
CREATE PROCEDURE [dbo].[GetReconciliationReport]
(
	@UserId BIGINT ,  
	@ModuleIterationStatusId BIGINT,  
	@CreatedTime DATETIMEOFFSET = NULL,  
	@DBName nvarchar(128),
	@TableNamesCsv varchar(MAX),
	@ModuleName Nvarchar(max) = 'MigrateModule'
)
AS
--DECLARE @UserId BIGINT =1;  
--DECLARE @CreatedTime DATETIMEOFFSET=SYSDATETIMEOFFSET();  
--DECLARE @ModuleIterationStatusId BIGINT;  
--DECLARE @ModuleName Nvarchar(max) = 'MigrateModule'
--DECLARE @TableNamesCsv varchar(MAX)='StaticHistoryAsset#StaticHistoryAssets,StaticHistoryLocation#StaticHistoryLocations,StaticHistoryAssetHistory#StaticHistoryAssetHistories,StaticHistoryAssetLocationHistory#StaticHistoryAssetLocationHistories,StaticHistoryAssetValueHistory#StaticHistoryAssetValueHistories';
--DECLARE @DBName nvarchar(128) = 'Intermediate_RS';
--SET @ModuleIterationStatusId = 10465;  
--SELECT @ModuleIterationStatusId = IsNull(MAX(ModuleIterationStatusId),0) from stgProcessingLog;  
BEGIN
SET NOCOUNT ON;  
set XACT_ABORT ON;
CREATE TABLE #TableNames
(
	Id int identity(1,1),
	Name varchar(100),
	StagingName varchar(100),
	StagingRecordCount BIGINT,
	TargetName varchar(100),
	TargetRecordCount BIGINT,
	Result varchar(100)
);

CREATE TABLE #ProcessingLog(Id int);

SET @TableNamesCsv = Replace(@TableNamesCsv, '#', '.')
INSERT into #TableNames (Name,TargetName,StagingName) 
SELECT Item [TableName],TargetName = ParseName(Item, 1), StagingName =  ParseName(Item, 2) 
FROM ConvertCSVToStringTable(@TableNamesCsv, ',')

DECLARE @query nvarchar(max) =''
DEClare @TotalNumberOfTables  int
DEClare @StagingRecords  BIGINT
DEClare @TargetRecords  BIGINT
SELECT @TotalNumberOfTables = COUNT(*) from #TableNames
DECLARE @Count INT = 1
DECLARE @TargetTable nvarchar(MAX) = ''
DECLARE @StagingTable nvarchar(MAX) = ''
DECLARE @ProcessingLogId BIGINT

BEGIN TRY
	WHILE @Count <= @TotalNumberOfTables
	BEGIN
		SELECT @TargetTable = TargetName, @StagingTable = StagingName FROM #TableNames WHERE Id = @Count

		SET @query = 'SELECT @NumberOfStagingRecords =  COUNT(*) FROM ' + @DBName + '.dbo.'+ @StagingTable 
		+'; SELECT @NumberOfTargetRecords =  COUNT(*) FROM dbo.'+ @TargetTable ;
		EXECUTE sp_executesql @query, N'@NumberOfTargetRecords BIGINT OUTPUT,@NumberOfStagingRecords BIGINT OUTPUT', @NumberOfTargetRecords = @TargetRecords OUTPUT,@NumberOfStagingRecords = @StagingRecords OUTPUT
		
		SET @query = 'UPDATE #TableNames SET StagingRecordCount = '+ CAST(@StagingRecords as varchar(15))+ ', TargetRecordCount = '+ CAST(@TargetRecords as varchar(15))+
		' where Id = '+CAST(@Count as varchar(15))
		EXEC sp_executesql @query

		SET @Count = @Count+1
	END
		UPDATE #TableNames SET Result = CASE WHEN StagingRecordCount = TargetRecordCount Then 'Success' ELSE 'Failed' END FROM #TableNames

		INSERT INTO stgProcessingLog(StagingRootEntityId,CreatedById,CreatedTime,ModuleIterationStatusId)  OUTPUT Inserted.Id INTO #ProcessingLog
		VALUES (0, @UserId, @CreatedTime,@ModuleIterationStatusId)
		SELECT TOP 1 @ProcessingLogId = Id FROM #ProcessingLog;
		INSERT INTO stgProcessingLogDetail(Message,Type,EntityName,CreatedById,CreatedTime,ProcessingLogId)
		SELECT StagingName+':'+CAST(StagingRecordCount as varchar(15))+','+TargetName+':'+CAST(TargetRecordCount as varchar(15))+','+Result,'Information',TargetName, @UserId, @CreatedTime,@ProcessingLogId  FROM #TableNames

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
	END;
END CATCH
DROP TABLE IF EXISTS #TableNames
SET NOCOUNT OFF
SET XACT_ABORT OFF
END

GO
