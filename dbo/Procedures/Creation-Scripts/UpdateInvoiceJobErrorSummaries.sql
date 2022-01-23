SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateInvoiceJobErrorSummaries]
(
	@JobStepInstanceId BIGINT,
	@SourceJobStepInstanceId BIGINT = NULL,
	@CreatedById BIGINT,
	@CreatedTime DATE,
	@TotalInvoicesGenerated BIGINT OUTPUT, 
	@TotalStatementInvoicesGenerated BIGINT OUTPUT,
	@TotalInvoicesExtracted BIGINT OUTPUT, 
	@HasReceivablesToProcess BIT OUTPUT,
	@HasInvalidGroup BIT OUTPUT,
	@InvoiceGenerationAction_ReceivableInvoiceGeneration NVARCHAR(100),
	@InvoiceGenerationAction_StatementInvoiceGeneration NVARCHAR(100),
	@InvoiceGenerationAction_FileGeneration NVARCHAR(100),
	@InvoiceGenerationAction_InvoiceExtraction NVARCHAR(100),
	@InvoiceGenerationAction_Unknown NVARCHAR(100),
	@InvoiceChunkStatus_Faulted NVARCHAR(100)
)
AS 
BEGIN

	DECLARE @True AS BIT = CONVERT(BIT, 1)
	DECLARE @False AS BIT = CONVERT(BIT, 0)

	SET @SourceJobStepInstanceId = ISNULL(@SourceJobStepInstanceId, @JobStepInstanceId);

	CREATE TABLE #PreviousBillToFaultedActions(
		JobErrorSummaryId BIGINT,
		BillToId BIGINT,
		PreviousFaultedAction NVARCHAR(27)
	)

	INSERT INTO #PreviousBillToFaultedActions(JobErrorSummaryId, BillToId, PreviousFaultedAction)
	SELECT Id, BillToId, NextAction
	FROM InvoiceJobErrorSummaries WHERE SourceJobStepInstanceId=@SourceJobStepInstanceId AND IsActive=1
	
	CREATE TABLE #CurrentStatusBillToActions(
		BillToId BIGINT,

		[Action] NVARCHAR(27) NULL,
		InvoicingStatus NVARCHAR(10),
	)

	INSERT INTO #CurrentStatusBillToActions(BillToId, [Action], InvoicingStatus)
	SELECT 
		ICD.BillToId,
		CASE
			WHEN (ICS.IsReceivableInvoiceProcessed = @False) THEN @InvoiceGenerationAction_ReceivableInvoiceGeneration
			WHEN (ICS.IsStatementInvoiceProcessed = @False) THEN @InvoiceGenerationAction_StatementInvoiceGeneration
			WHEN (ICS.IsExtractionProcessed = @False) THEN @InvoiceGenerationAction_InvoiceExtraction
			WHEN (ICS.IsFileGenerated = @False) THEN @InvoiceGenerationAction_FileGeneration
			ELSE @InvoiceGenerationAction_Unknown
		END [Action],
		ICS.InvoicingStatus
	FROM InvoiceChunkStatus_Extract ICS 
	INNER JOIN InvoiceChunkDetails_Extract ICD ON ICS.ChunkNumber=ICD.ChunkNumber
	WHERE ICS.RunJobStepInstanceId=@JobStepInstanceId AND ICD.JobStepInstanceId=@JobStepInstanceId

	CREATE TABLE #CurrentInstanceGenerationCount(
		BillToId BIGINT,
		ConsiderForInvoiceCount BIT,
		ConsiderForStatementInvoiceCount BIT,
		ConsiderForExtractionCount BIT,
		ShowFileMessage BIT
	)

	--Decide which BillToes to consider while calculating totals
	INSERT INTO #CurrentInstanceGenerationCount(BillToId, ConsiderForInvoiceCount, ConsiderForStatementInvoiceCount, ConsiderForExtractionCount, ShowFileMessage)
	SELECT
	C.BillToId,
	ConsiderForInvoiceCount = CASE
		WHEN P.BillToId IS NULL THEN @True
		WHEN (P.PreviousFaultedAction =@InvoiceGenerationAction_ReceivableInvoiceGeneration AND (C.[Action] != @InvoiceGenerationAction_ReceivableInvoiceGeneration)) THEN @True
		ELSE @False
	END,
	ConsiderForStatementInvoiceCount = CASE
		WHEN P.BillToId IS NULL THEN @True
		WHEN (P.PreviousFaultedAction IN (@InvoiceGenerationAction_ReceivableInvoiceGeneration,@InvoiceGenerationAction_StatementInvoiceGeneration) AND C.[Action] NOT IN (@InvoiceGenerationAction_ReceivableInvoiceGeneration,@InvoiceGenerationAction_StatementInvoiceGeneration)) THEN @True
		ELSE @False
	END,
	ConsiderForExtractionCount = CASE
		WHEN P.BillToId IS NULL THEN @True
		WHEN (P.PreviousFaultedAction != @InvoiceGenerationAction_FileGeneration AND C.[Action] IN (@InvoiceGenerationAction_FileGeneration, '_')) THEN @True
		ELSE @False
	END,
	ShowFileMessage = CASE
		WHEN C.[Action]=@InvoiceGenerationAction_Unknown THEN @True
		ELSE @False
	END
	FROM #CurrentStatusBillToActions C
	LEFT JOIN #PreviousBillToFaultedActions P ON C.BillToId = P.BillToId 


	SET @TotalInvoicesGenerated = 0
	SET @TotalStatementInvoicesGenerated = 0
	SET @TotalInvoicesExtracted = 0

	--Update Output Variables with Proper Count for Logging Info
	SET @TotalInvoicesGenerated = (
		SELECT COUNT(RI.Id) FROM ReceivableInvoices RI 
		INNER JOIN #CurrentInstanceGenerationCount C ON RI.BillToId = C.BillToId AND C.ConsiderForInvoiceCount = 1
		WHERE RI.JobStepInstanceId=@SourceJobStepInstanceId AND RI.IsStatementInvoice=0
	)

	SET @TotalStatementInvoicesGenerated = (
		SELECT COUNT(RI.Id) FROM ReceivableInvoices RI
		INNER JOIN #CurrentInstanceGenerationCount C ON RI.BillToId = C.BillToId AND C.ConsiderForStatementInvoiceCount = 1
		WHERE RI.JobStepInstanceId=@SourceJobStepInstanceId AND RI.IsStatementInvoice=1
	)

	SET @TotalInvoicesExtracted = (
		SELECT COUNT(I.Id) FROM InvoiceExtractCustomerDetails I
		INNER JOIN #CurrentInstanceGenerationCount C ON I.BillToId = C.BillToId AND C.ConsiderForExtractionCount = 1
		WHERE I.JobStepInstanceId=@SourceJobStepInstanceId
	)

	SET @HasReceivablesToProcess = @False

	--Check if No Receivables have been found for RI Generation for Logging Info
	IF EXISTS (SELECT TOP 1 1 FROM InvoiceReceivableDetails_Extract	WHERE JobStepInstanceId = @JobStepInstanceId AND IsActive=1)
		SET @HasReceivablesToProcess = @True
	
	--InActivating previous job summaries if exists
	UPDATE InvoiceJobErrorSummaries SET 
		IsActive = 0,
		UpdatedById = @CreatedById,
		UpdatedTime = @CreatedTime
	WHERE SourceJobStepInstanceId = @SourceJobStepInstanceId AND IsActive=1

	DECLARE @JobStepId BIGINT = 0
	SELECT @JobStepId = JobStepId FROM JobStepInstances WHERE Id=@JobStepInstanceId;
	
	--Update Faulted Actions for next re-run's consumption, if any
	INSERT INTO InvoiceJobErrorSummaries(
		BillToId,
		IsActive,
		JobStepId,
		RunJobStepInstanceId,
		SourceJobStepInstanceId,
		NextAction,
		CreatedById,
		CreatedTime
	)
	SELECT 
		C.BillToId,
		@True,
		@JobStepId,
		@JobStepInstanceId,
		@SourceJobStepInstanceId,
		C.[Action],
		@CreatedById,
		@CreatedTime
	FROM #CurrentStatusBillToActions C WHERE C.InvoicingStatus=@InvoiceChunkStatus_Faulted
	
	--Send back faulted BillToChunkDetails for Logging Errors
	SELECT B.Id AS BillToId, B.CustomerId AS CustomerId, C.[Action] AS NextAction
	FROM #CurrentStatusBillToActions C INNER JOIN BillToes B ON C.BillToId = B.Id 
	WHERE C.InvoicingStatus = @InvoiceChunkStatus_Faulted

	--Load Test by Fetching Non-XML records into code and run ToCSV
	;WITH InvoiceInfo AS (
		SELECT 
		B.Id BillToId,
		B.CustomerId,
		C.ShowFileMessage,
		InvoiceNumber = CASE WHEN IsStatementInvoice = @False AND C.ConsiderForInvoiceCount = @True THEN Number END,
		StatementNumber = CASE WHEN IsStatementInvoice = @True AND C.ConsiderForStatementInvoiceCount = @True THEN Number END
		FROM #CurrentInstanceGenerationCount C
		INNER JOIN ReceivableInvoices RI ON RI.JobStepInstanceId=@SourceJobStepInstanceId AND C.BillToId = RI.BillToId
		INNER JOIN BillToes B ON C.BillToId = B.Id										
	)
	SELECT 
	I3.BillToId AS BillToId, 
	I3.CustomerId AS CustomerId,
	I3.ShowFileMessage,
	Invoices = 
	ISNULL(STUFF((SELECT ', ' + InvoiceNumber from InvoiceInfo I1 WHERE I1.BillToId = I3.BillToId AND I1.InvoiceNumber IS NOT NULL FOR XML PATH('')), 1, 2, ''),''),
	StatementInvoices = 
	ISNULL(STUFF((SELECT ', ' + StatementNumber from InvoiceInfo I2 WHERE I2.BillToId = I3.BillToId AND I2.StatementNumber IS NOT NULL FOR XML PATH('')), 1, 2, ''),'')
	FROM InvoiceInfo I3
	GROUP BY I3.BillToId, I3.CustomerId, I3.ShowFileMessage

	-- Find any inactive group (validation due to invoice format)
	SET @HasInvalidGroup = @False
	IF EXISTS (SELECT TOP 1 1 FROM InvoiceReceivableDetails_Extract 
	WHERE JobStepInstanceId = @JobStepInstanceId AND IsActive = 0 AND GroupNumber > 0)
	BEGIN
		SET @HasInvalidGroup = @True
	END

	DROP TABLE #PreviousBillToFaultedActions
	DROP TABLE #CurrentStatusBillToActions
	DROP TABLE #CurrentInstanceGenerationCount
END

GO
