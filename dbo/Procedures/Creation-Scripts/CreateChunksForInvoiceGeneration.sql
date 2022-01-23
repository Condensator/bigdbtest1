SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[CreateChunksForInvoiceGeneration]
(
	@JobStepInstanceId										BIGINT,
	@ChunkSize												BIGINT,
	@CreatedById											BIGINT,
	@CreatedTime											DATETIMEOFFSET,
	@IsFileGenerationRequired								BIT,
	@SourceJobStepInstanceId								BIGINT = NULL,
	@InvoiceGenerationAction_ReceivableInvoiceGeneration	NVARCHAR(50),
	@InvoiceGenerationAction_InvoiceExtraction				NVARCHAR(50),
	@InvoiceGenerationAction_StatementInvoiceGeneration		NVARCHAR(50),
	@InvoiceChunkStatus_New									NVARCHAR(10)

)
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE @True AS BIT = CONVERT(BIT, 1)
	DECLARE @False AS BIT = CONVERT(BIT, 0)

	DECLARE @IsFileGenerated BIT
	SET @IsFileGenerated = (SELECT CASE WHEN @IsFileGenerationRequired = @True THEN @False ELSE @True END)

	CREATE TABLE #InvoicePickUpDetails(
		BillToId BIGINT NOT NULL PRIMARY KEY, 
		GenerateStatementInvoice BIT NOT NULL,
		CountOfInvoiceReceivableDetails BIGINT DEFAULT 0,
		CountOfInvoiceStatementDetails BIGINT DEFAULT 0, 
		ChunkNumber BIGINT NULL,
		IsReceivableInvoiceProcessed BIT NOT NULL,
		IsStatementInvoiceProcessed BIT NOT NULL,
		IsExtractionProcessed BIT NOT NULL,
		IsFileGenerated BIT NOT NULL 
	)

	CREATE TABLE #InvoiceStatementDetails(
		BillToId BIGINT NOT NULL PRIMARY KEY, 
		CountOfInvoiceStatementDetails BIGINT DEFAULT 0
	)

	CREATE TABLE #PreviousInvoiceRunDetails(
		BillToId BIGINT NOT NULL PRIMARY KEY,
		IsReceivableInvoiceProcessed BIT NOT NULL,
		IsStatementInvoiceProcessed BIT NOT NULL,
		IsExtractionProcessed BIT NOT NULL,
	)

	INSERT INTO #InvoicePickUpDetails(
		BillToId,
		GenerateStatementInvoice,
		CountOfInvoiceReceivableDetails,
		CountOfInvoiceStatementDetails,
		ChunkNumber,
		IsReceivableInvoiceProcessed,
		IsStatementInvoiceProcessed,
		IsExtractionProcessed,
		IsFileGenerated
	)
	SELECT 
		BillToId, 
		GenerateStatementInvoice,
		COUNT(1) AS CountOfDetails, 
		0 CountInvoiceStatementDetails,
		NULL ChunkNumber,
		@False AS IsReceivableInvoiceProcessed,
		IsStatementInvoiceProcessed=
		CASE
			WHEN GenerateStatementInvoice = @True THEN @False --GenerateStatementInvoice reflects IsStatementInvoiceProcessed, thus not needed as additional Grouping param
			ELSE @True
		END,
		@False AS IsExtractionProcessed,
		IsFileGenerated= @IsFileGenerated
	FROM InvoiceReceivableDetails_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND IsActive=1
	GROUP BY BillToId, GenerateStatementInvoice

	--Sync Statement Invoice Details
	INSERT INTO #InvoiceStatementDetails(
		BillToId,
		CountOfInvoiceStatementDetails
	)
	SELECT 
		BillToId, 
		COUNT(1) AS CountOfStatementDetails
	FROM StatementInvoiceReceivableDetails_Extract WHERE JobStepInstanceId = @JobStepInstanceId
	GROUP BY BillToId

	MERGE #InvoicePickUpDetails AS T
	USING (
		SELECT BillToId, CountOfInvoiceStatementDetails
		FROM #InvoiceStatementDetails
	) AS S ON ( T.BillToId = S.BillToId)
	WHEN MATCHED THEN
		UPDATE SET CountOfInvoiceStatementDetails = S.CountOfInvoiceStatementDetails
	WHEN NOT MATCHED THEN
		INSERT (BillToId, GenerateStatementInvoice, CountOfInvoiceReceivableDetails, CountOfInvoiceStatementDetails, ChunkNumber,
		IsReceivableInvoiceProcessed, IsStatementInvoiceProcessed, IsExtractionProcessed, IsFileGenerated)
		VALUES (S.BillToId, @True, 0, S.CountOfInvoiceStatementDetails, NULL, @True, @False, @False, @IsFileGenerated);

	--Sync other BillToes which may be present for Extraction/FileGeneration if not matched. Else, if matched, overwrite chunk processing bits.
	IF @SourceJobStepInstanceId IS NOT NULL
	BEGIN
		INSERT INTO #PreviousInvoiceRunDetails(
		BillToId,
		IsReceivableInvoiceProcessed,
		IsStatementInvoiceProcessed,
		IsExtractionProcessed
		--For File Generation, Re-Run will not change parameters, thus @IsFileGenerationRequired shall remain the same value
		--Generate Statement Invoice is being marked for ones didn't match
		)
		SELECT
			BillToId,
			IsReceivableInvoiceProcessed = 
			CASE 
				WHEN NextAction=@InvoiceGenerationAction_ReceivableInvoiceGeneration THEN @False
				ELSE @True
			END,
			IsStatementInvoiceProcessed = 
			CASE 
				WHEN NextAction=@InvoiceGenerationAction_ReceivableInvoiceGeneration OR NextAction=@InvoiceGenerationAction_StatementInvoiceGeneration THEN @False
				ELSE @True
			END,
			IsExtractionProcessed = 
			CASE 
				WHEN NextAction=@InvoiceGenerationAction_ReceivableInvoiceGeneration OR NextAction=@InvoiceGenerationAction_StatementInvoiceGeneration OR NextAction=@InvoiceGenerationAction_InvoiceExtraction THEN @False
				ELSE @True
			END
		FROM InvoiceJobErrorSummaries J WHERE SourceJobStepInstanceId = @SourceJobStepInstanceId AND IsActive=1

		MERGE #InvoicePickUpDetails AS T
		USING (
			SELECT BillToId, IsReceivableInvoiceProcessed, IsStatementInvoiceProcessed, IsExtractionProcessed FROM #PreviousInvoiceRunDetails
		) AS S ON ( T.BillToId = S.BillToId)
		WHEN MATCHED THEN
			UPDATE SET IsReceivableInvoiceProcessed = S.IsReceivableInvoiceProcessed, IsStatementInvoiceProcessed = S.IsStatementInvoiceProcessed, IsExtractionProcessed = S.IsExtractionProcessed
		WHEN NOT MATCHED THEN
			INSERT (BillToId, GenerateStatementInvoice, CountOfInvoiceReceivableDetails, CountOfInvoiceStatementDetails, ChunkNumber,
			IsReceivableInvoiceProcessed, IsStatementInvoiceProcessed, IsExtractionProcessed, IsFileGenerated)
			VALUES (S.BillToId, @False, 0, 0, NULL, S.IsReceivableInvoiceProcessed, S.IsStatementInvoiceProcessed, S.IsExtractionProcessed, @IsFileGenerated);
	END

	--Now InvoicePickUpDetails has all the Details required to group the Unique Billtoes of #InvoicePickUpDetails into Chunks. 
	
	CREATE TABLE #BillToChunk (
		BillToId		BIGINT PRIMARY KEY,
		ChunkId			INT
	)

	--Tabular Approach
	DECLARE @MaxChunkNumber INT = 0

	;WITH BigChunks AS(
		SELECT BillToId, (CountOfInvoiceReceivableDetails) ,  ROW_NUMBER() OVER (ORDER BY BillToId) AS Number
		FROM #InvoicePickUpDetails WHERE CountOfInvoiceReceivableDetails>=@ChunkSize OR CountOfInvoiceStatementDetails>=@ChunkSize --TODO: SIDataPrepLT and Check SpecFlow
	)
	INSERT INTO #BillToChunk(BillToId, ChunkId) 
	SELECT BillToId, Number
	FROM BigChunks 

	SET @MaxChunkNumber = ISNULL((SELECT MAX(ChunkId) FROM #BillToChunk), 0) + 1

	SELECT 
		BillToId, 
		DENSE_RANK() OVER (ORDER BY IsReceivableInvoiceProcessed, IsStatementInvoiceProcessed, IsExtractionProcessed, IsFileGenerated) AS ChunkConfigurationId
	INTO #BillToGroupConfigs
	FROM #InvoicePickUpDetails WHERE CountOfInvoiceReceivableDetails<@ChunkSize AND CountOfInvoiceStatementDetails<@ChunkSize --TODO: SIDataPrepLT and Check SpecFlow

	;WITH RunningTotal AS (
		SELECT 
			#InvoicePickUpDetails.BillToId, 
			#BillToGroupConfigs.ChunkConfigurationId,
			SUM(CountOfInvoiceReceivableDetails) OVER 
				(PARTITION BY #BillToGroupConfigs.ChunkConfigurationId ORDER BY #InvoicePickUpDetails.BillToId) AS Total 
		FROM #InvoicePickUpDetails
		INNER JOIN #BillToGroupConfigs ON #InvoicePickUpDetails.BillToId=#BillToGroupConfigs.BillToId
	), AssignedChunkNumbers AS(
		SELECT
			BillToId,
			ChunkConfigurationId,
			Total/@ChunkSize AS RoundedWithinChunkConfig
		FROM RunningTotal
	), NewAssigned AS(
		SELECT BillToId, ChunkConfigurationId, (DENSE_RANK() OVER (ORDER BY A.ChunkConfigurationId, A.RoundedWithinChunkConfig) + @MaxChunkNumber)
		AS Number
		FROM AssignedChunkNumbers A
	)
	INSERT INTO #BillToChunk(BillToId, ChunkId) 
	SELECT BillToId, Number
	FROM NewAssigned A 

	INSERT INTO InvoiceChunkDetails_Extract(
		BillToId,
		ChunkNumber,
		GenerateStatementInvoice, --Do we need GSI in ChunkDetails? 
		JobStepInstanceId,
		ReceivableDetailsCount,
		CreatedById,
		CreatedTime
	)
	SELECT 
		I.BillToId,
		C.ChunkId,
		I.GenerateStatementInvoice,
		@JobStepInstanceId,
		I.CountOfInvoiceReceivableDetails + I.CountOfInvoiceStatementDetails,
		@CreatedById,
		@CreatedTime
	FROM #InvoicePickUpDetails I
	INNER JOIN #BillToChunk C ON I.BillToId = C.BillToId

	INSERT INTO InvoiceChunkStatus_Extract(
		RunJobStepInstanceId,
		ChunkNumber,
		TaskChunkServiceInstanceId,
		CreatedById,
		CreatedTime,
		InvoicingStatus,
		IsReceivableInvoiceProcessed,
		IsStatementInvoiceProcessed,
		IsExtractionProcessed,
		IsFileGenerated
	)
	SELECT
		@JobStepInstanceId,
		ICD.ChunkNumber,
		NULL,
		@CreatedById,
		@CreatedTime,
		@InvoiceChunkStatus_New,
		I.IsReceivableInvoiceProcessed,
		I.IsStatementInvoiceProcessed,
		I.IsExtractionProcessed,
		I.IsFileGenerated
	FROM InvoiceChunkDetails_Extract ICD 
	INNER JOIN #InvoicePickUpDetails I ON ICD.BillToId=I.BillToId AND ICD.JobStepInstanceId=@JobStepInstanceId
	GROUP BY ICD.ChunkNumber, I.IsReceivableInvoiceProcessed, I.IsStatementInvoiceProcessed, I.IsExtractionProcessed, I.IsFileGenerated
	
	DROP TABLE #InvoicePickUpDetails
	DROP TABLE #BillToChunk
	DROP TABLE #BillToGroupConfigs
	DROP TABLE #InvoiceStatementDetails
	DROP TABLE #PreviousInvoiceRunDetails
END

GO
