SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[MigrateCPUMeterReadings]
(
	 @InstanceId uniqueidentifier
	 ,@ModuleIterationStatusId BIGINT
	 ,@UserId BIGINT
	 ,@CreatedTime DATETIMEOFFSET= NULL
	 ,@ProcessedRecords BIGINT OUTPUT
	 ,@FailedRecords BIGINT OUTPUT
	 ,@ToolIdentifier INT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY  
		BEGIN TRANSACTION;
			SET @FailedRecords = 0  
			SET @ProcessedRecords = 0  
Select @ProcessedRecords = ISNULL(COUNT(Id), 0) FROM stgCPUAssetMeterReadingUploadRecord WHERE IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier)
			INSERT INTO EnmasseMeterReadingInputs 
			(
				CPINumber,
				Alias,
				MeterType,
				EndPeriodDate,
				ReadDate,
				BeginReading,
				EndReading,
				ServiceCredits,
				Source,
				IsEstimated,
				MeterResetType,
				InstanceId,
				CreatedById,
				CreatedTime
			)
			SELECT 
				CPINumber,
				Alias,
				MeterType,
				EndPeriodDate,
				ReadDate,
				BeginReading,
				EndReading,
				ServiceCredits,
				Source,
				IsEstimated,
				MeterResetType,
				@InstanceId,
				@UserId,
				@CreatedTime
			FROM 
				stgCPUAssetMeterReadingUploadRecord
			Where 
				IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier)
		COMMIT TRANSACTION;
	END TRY 
	BEGIN CATCH 
		CREATE TABLE #FailedProcessingLogs 
		(
			[Action] NVARCHAR(10) NOT NULL, 
			[Id] BIGINT NOT NULL
		);  
		MERGE 
			stgProcessingLog AS ProcessingLog  
		USING 
			(SELECT 1 AS Id) AS ErrorMessage  
		ON 
			(1 = 0)  
		WHEN 
			NOT MATCHED 
			THEN
				INSERT  
				(  
					StagingRootEntityId  
					,CreatedById  
					,CreatedTime  
					,ModuleIterationStatusId  
				)  
				VALUES  
				(  
					ErrorMessage.Id
					,@UserId  
					,@CreatedTime  
					,@ModuleIterationStatusId  
				)  
		OUTPUT 
			$action, Inserted.Id 
		INTO 
			#FailedProcessingLogs;   
		INSERT INTO stgProcessingLogDetail  
		(  
			Message  
			,Type  
			,CreatedById  
			,CreatedTime   
			,ProcessingLogId  
		)  
		SELECT
			(SELECT ERROR_MESSAGE() AS ErrorMessage)
			,'Error'  
			,@UserId  
			,@CreatedTime  
			,#FailedProcessingLogs.Id
		FROM   
			#FailedProcessingLogs
		Select @FailedRecords = ISNULL(COUNT(Id), 0) FROM #FailedProcessingLogs
		DROP TABLE #FailedProcessingLogs;  
	END CATCH;
	SET NOCOUNT OFF;
END  

GO
