SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateLateFeeAssessmentsForMigratedInvoices]
(
	@UserId BIGINT,
	@ModuleIterationStatusId BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@ProcessedRecords BIGINT OUTPUT,
	@FailedRecords BIGINT OUTPUT,
	@ToolIdentifier INT
)
AS
BEGIN
BEGIN TRY  
BEGIN TRANSACTION
SET XACT_ABORT ON
SET NOCOUNT ON
SET @FailedRecords = 0
SET @ProcessedRecords = 0
DECLARE @BatchCount INT = 0
CREATE TABLE #CreatedProcessingLogs 
(
	[Id] bigint NOT NULL,
	[LateFeeHistoryId] bigint
)
CREATE TABLE #LateFeeWithoutContract
(
	[CSV] NVARCHAR(MAX), 
	[EntityId] BIGINT
);  
CREATE TABLE #FailedProcessingLogs
(	
	[Id] BIGINT NOT NULL, 
	[LateFeeHistoryId] BIGINT NOT NULL
);  
	IF(@CreatedTime IS NULL)
	SET @CreatedTime = SYSDATETIMEOFFSET();
	SELECT @ProcessedRecords = ISNULL(COUNT(Id), 0) FROM stgLateFeeHistory WHERE IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier)
	SELECT Id, SequenceNumber INTO #ProcessableLateFeeHistoryTemp
	FROM 
	stgLateFeeHistory
	WHERE IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier)
	SELECT @BatchCount = COUNT(Id) FROM #ProcessableLateFeeHistoryTemp
	INSERT INTO #LateFeeWithoutContract
	SELECT 'SequenceNumber provided is not valid for :['+CONVERT(nvarchar(10),lateFeeHistory.Id)+']', lateFeeHistory.Id
	FROM #ProcessableLateFeeHistoryTemp AS lateFeeHistory
	LEFT JOIN dbo.Contracts c On c.SequenceNumber=lateFeeHistory.SequenceNumber
	WHERE c.Id IS NULL

	DELETE FROM #ProcessableLateFeeHistoryTemp WHERE Id IN (SELECT EntityId FROM #LateFeeWithoutContract)

	SELECT DISTINCT
		LateFeeHistory.Id
	INTO #NoReceivableRecordsFound
	FROM 
		#ProcessableLateFeeHistoryTemp
	INNER JOIN stgLateFeeHistory LateFeeHistory 
		ON #ProcessableLateFeeHistoryTemp.Id = LateFeeHistory.Id
	INNER JOIN Contracts
		ON LateFeeHistory.SequenceNumber = Contracts.SequenceNumber
	LEFT JOIN ReceivableInvoiceDetails 
		ON ReceivableInvoiceDetails.EntityId = Contracts.Id AND
			ReceivableInvoiceDetails.EntityType = 'CT' AND
			ReceivableInvoiceDetails.IsActive = 1 
	LEFT JOIN ReceivableInvoices
		ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id  AND
			ReceivableInvoices.IsActive = 1 AND ReceivableInvoices.DueDate <= LateFeeHistory.AssessedUntilDate
	WHERE
		ReceivableInvoices.Id IS NULL

	DELETE FROM #ProcessableLateFeeHistoryTemp WHERE Id IN (SELECT Id FROM #NoReceivableRecordsFound)

	INSERT INTO LateFeeAssessments
	(
		LateFeeAssessedUntilDate, FullyAssessed, IsActive, CreatedTime, CreatedById, ContractId, ReceivableInvoiceId
	)
	SELECT
		CASE 
		WHEN LateFeeTemplate.IsAssessedOnlyOnce=0 THEN LateFeeHistory.AssessedUntilDate
		ELSE DATEADD(Month,1,(DATEADD(DAY,1,ReceivableInvoices.DueDate)))
		END,
		LateFeeHistory.IsFullyAssessed,
		1,
		@CreatedTime,
		@UserId,
		EntityId ContractId,
		ReceivableInvoices.Id InvoiceId
	FROM 
		#ProcessableLateFeeHistoryTemp
	INNER JOIN stgLateFeeHistory LateFeeHistory 
		ON #ProcessableLateFeeHistoryTemp.Id = LateFeeHistory.Id
	INNER JOIN Contracts
		ON LateFeeHistory.SequenceNumber = Contracts.SequenceNumber
	LEFT JOIN ContractLateFees ContractLateFee
		ON Contracts.Id=ContractLateFee.Id
	LEFT JOIN LateFeeTemplates LateFeeTemplate
		ON LateFeeTemplate.Id=ContractLateFee.LateFeeTemplateId	
	INNER JOIN ReceivableInvoiceDetails 
		ON ReceivableInvoiceDetails.EntityId = Contracts.Id AND
           ReceivableInvoiceDetails.EntityType = 'CT' AND
           ReceivableInvoiceDetails.IsActive = 1 
	INNER JOIN ReceivableInvoices
		ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id  AND
           ReceivableInvoices.IsActive = 1
	WHERE
		ReceivableInvoices.DueDate <= LateFeeHistory.AssessedUntilDate
	GROUP BY 
		ReceivableInvoices.DueDate,
		ReceivableInvoices.Id,
		ReceivableInvoiceDetails.EntityId,
		LateFeeHistory.IsFullyAssessed,
		LateFeeHistory.AssessedUntilDate,
		LateFeeTemplate.IsAssessedOnlyOnce

	MERGE stgProcessingLog AS ProcessingLog  
	USING (SELECT DISTINCT EntityId StagingRootEntityId FROM #LateFeeWithoutContract) AS Errors
	ON (1 = 0)  
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
			Errors.StagingRootEntityId  
			,@UserId  
			,@CreatedTime  
			,@ModuleIterationStatusId  
		)  
	OUTPUT Inserted.Id,Errors.StagingRootEntityId INTO #FailedProcessingLogs;   
	INSERT INTO stgProcessingLogDetail  
		(  
			Message  
			,Type  
			,CreatedById  
			,CreatedTime   
			,ProcessingLogId  
		)  
	SELECT  
			#LateFeeWithoutContract.CSV  
			,'Error'  
			,@UserId  
			,@CreatedTime  
			,#FailedProcessingLogs.Id  
	FROM  
	#LateFeeWithoutContract  
	INNER JOIN #FailedProcessingLogs  
	ON #LateFeeWithoutContract.EntityId = #FailedProcessingLogs.LateFeeHistoryId  
	MERGE stgProcessingLog AS ProcessingLog
	USING (SELECT latefee.Id FROM #ProcessableLateFeeHistoryTemp latefee) AS ProcessedLateFeeAssessmentsForMigratedInvoices
	ON (1 = 0)
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
			ProcessedLateFeeAssessmentsForMigratedInvoices.Id
			,@UserId
			,@CreatedTime
			,@ModuleIterationStatusId
		)
	OUTPUT Inserted.Id, NULL INTO #CreatedProcessingLogs;
	INSERT INTO stgProcessingLogDetail
		(
			Message
			,Type
			,CreatedById
			,CreatedTime	
			,ProcessingLogId
		)
	SELECT
		'Successful'
		,'Information'
		,@UserId
		,@CreatedTime
		,Id
	FROM
		#CreatedProcessingLogs
	DELETE FROM #CreatedProcessingLogs;
	MERGE stgProcessingLog AS ProcessingLog
	USING (SELECT Id FROM #NoReceivableRecordsFound) AS Processed
	ON (1 = 0)
	WHEN NOT MATCHED THEN
	INSERT
		(StagingRootEntityId
		,CreatedById
		,CreatedTime
		,ModuleIterationStatusId)
	VALUES
		(Processed.Id
		,@UserId
		,@CreatedTime
		,@ModuleIterationStatusId)
	OUTPUT Inserted.Id, Processed.Id INTO #CreatedProcessingLogs;
	INSERT INTO stgProcessingLogDetail
			(Message
			,Type
			,CreatedById
			,CreatedTime	
			,ProcessingLogId)
	SELECT
			'No receivable invoices(s) found as of ' + Convert(nvarchar(50),ISNULL(AssessedUntilDate,@CreatedTime)) + ' for contract: ' + SequenceNumber
			,'Warning'
			,@UserId
			,@CreatedTime
			,CreatedProcessingLogs.Id
	FROM
	#CreatedProcessingLogs CreatedProcessingLogs
	INNER JOIN stgLateFeeHistory LateFeeHistory ON CreatedProcessingLogs.LateFeeHistoryId = LateFeeHistory.Id
	WHERE
	LateFeeHistory.IsMigrated = 0 AND (LateFeeHistory.ToolIdentifier IS NULL OR LateFeeHistory.ToolIdentifier = @ToolIdentifier)
	UPDATE stgLateFeeHistory SET IsMigrated = 1 WHERE Id IN 
	(SELECT Id FROM #ProcessableLateFeeHistoryTemp
	UNION ALL
	select Id from #NoReceivableRecordsFound
	)

	UPDATE ReceivableInvoices set LastReceivedDate = DueDate, UpdatedById=1, UpdatedTime = SYSDATETIMEOFFSET() from ReceivableInvoices  where Balance_Amount=0.00

COMMIT TRANSACTION
END TRY
BEGIN CATCH
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'CreateLateFeeAssessmentsForMigratedInvoices'
	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		set @FailedRecords = @FailedRecords+@BatchCount;
	END;  
	ELSE IF (XACT_STATE()) = 1  
	BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
	END; 
	ELSE
	BEGIN
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
        SET @FailedRecords = @FailedRecords+@BatchCount;
	END;
END CATCH
 SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT EntityId) FROM #LateFeeWithoutContract);
DROP TABLE #CreatedProcessingLogs
DROP TABLE #LateFeeWithoutContract
DROP TABLE #ProcessableLateFeeHistoryTemp
DROP TABLE #FailedProcessingLogs
DROP TABLE #NoReceivableRecordsFound
SET XACT_ABORT OFF
SET NOCOUNT OFF
END

GO
