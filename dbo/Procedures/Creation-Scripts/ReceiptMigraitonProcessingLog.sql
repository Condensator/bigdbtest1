SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ReceiptMigraitonProcessingLog]
(
	  @ModuleIterationStatusId BIGINT
	 ,@UserId BIGINT
	 ,@CreatedTime DATETIMEOFFSET= NULL
	 ,@JobStepInstanceId BIGINT
	 ,@ProcessedRecords BIGINT OUTPUT
	 ,@FailedRecords BIGINT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
			SET @FailedRecords = 0  
			SET @ProcessedRecords = 0 
  
			CREATE TABLE #CreatedProcessingLogs
			(
			Id BIGINT
			)
			
			CREATE TABLE #FailedProcessingLogs
			(
			Action NVARCHAR(20),
			Id BIGINT,
			StagingRootEntityId BIGINT
			)

			MERGE stgProcessingLog AS ProcessingLog
			USING (SELECT ReceiptMigrationId AS Id FROM ReceiptMigration_Extract Where JobStepInstanceId = @JobStepInstanceId				
				  AND IsValid = 1) AS ProcessedReceipts
			ON (ProcessingLog.StagingRootEntityId = ProcessedReceipts.Id AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
			WHEN MATCHED THEN
				UPDATE SET UpdatedTime = @CreatedTime
			WHEN NOT MATCHED THEN
			INSERT
				(
					StagingRootEntityId
				   ,CreatedById
				   ,CreatedTime
				   ,ModuleIterationStatusId
				)
			VALUES
				(
					ProcessedReceipts.Id
				   ,@UserId
				   ,@CreatedTime
				   ,@ModuleIterationStatusId
				)
			OUTPUT  Inserted.Id INTO #CreatedProcessingLogs;
			
			INSERT INTO stgProcessingLogDetail
			(
				Message
			   ,Type
			   ,CreatedById
			   ,CreatedTime	
			   ,ProcessingLogId
			   ,EntityName
			)
			SELECT
				'Successful'
			   ,'Information'
			   ,@UserId
			   ,@CreatedTime
			   ,Id
			   ,'CreateReceiptMigration'
			FROM
				#CreatedProcessingLogs
				
			SELECT @ProcessedRecords = ISNULL(COUNT(Id) ,0) FROM #CreatedProcessingLogs
		
			MERGE stgProcessingLog AS ProcessingLog  
		    USING (SELECT  
			ReceiptMigrationId as StagingRootEntityId FROM ReceiptMigration_Extract Where JobStepInstanceId = @JobStepInstanceId			
						  AND IsValid = 0) AS ErrorReceipts
			ON (ProcessingLog.StagingRootEntityId = ErrorReceipts.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)  
			WHEN MATCHED THEN  
			UPDATE SET UpdatedTime = @CreatedTime  
			WHEN NOT MATCHED THEN  
			
			INSERT  
			(  
			   StagingRootEntityId  
			  ,CreatedById  
			  ,CreatedTime  
			  ,ModuleIterationStatusId  
			)  
			VALUES  
			(  
			  ErrorReceipts.StagingRootEntityId  
			  ,@UserId  
			  ,@CreatedTime  
			  ,@ModuleIterationStatusId  
			 )  
			OUTPUT $action, Inserted.Id,ErrorReceipts.StagingRootEntityId INTO #FailedProcessingLogs;   
			
			INSERT INTO   
			 stgProcessingLogDetail  
			 (  
				   Message  
				  ,Type  
				  ,CreatedById  
				  ,CreatedTime   
				  ,ProcessingLogId
				  ,EntityName
			 )  
			  SELECT  
				  ErrorMessage 
				 ,'Error'  
				 ,@UserId  
				 ,@CreatedTime  
				 ,#FailedProcessingLogs.Id  
				 ,'CreateReceiptMigration'
			  FROM
			   ReceiptMigration_Extract
			   INNER JOIN #FailedProcessingLogs ON #FailedProcessingLogs.StagingRootEntityId = ReceiptMigration_Extract.ReceiptMigrationId
			  Where JobStepInstanceId = @JobStepInstanceId			
							  AND IsValid = 0
		
			SELECT @FailedRecords = ISNULL(COUNT(Id) ,0) FROM 	#FailedProcessingLogs
				
DROP TABLE #CreatedProcessingLogs				
DROP TABLE #FailedProcessingLogs;   
END

GO
