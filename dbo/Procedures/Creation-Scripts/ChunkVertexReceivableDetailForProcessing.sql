SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ChunkVertexReceivableDetailForProcessing] (
	@BatchCount BIGINT,
	@NewBatchStatus NVARCHAR(10),
	@UnknownTaxBasis NVARCHAR(10),
	@JobStepInstanceId BIGINT,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET
	)
AS
BEGIN
	CREATE TABLE #ChunkedVertexWSTransactionIds (Id BIGINT)

	DECLARE @ContinueProcessing BIT = 1;
	DECLARE @ScopeIdentity BIGINT;

	WHILE @ContinueProcessing = 1
	BEGIN
		INSERT INTO #ChunkedVertexWSTransactionIds
		SELECT TOP (@BatchCount)
		WITH TIES VTE.Id
		FROM VertexWSTransactionExtract VTE
		LEFT JOIN VertexWSTransactionChunkDetailsExtract VTECD ON VTE.Id = VTECD.VertexWSTransactionId
			AND VTECD.JobStepInstanceId = @JobStepInstanceId
		WHERE VTE.JobStepInstanceId = @JobStepInstanceId
			AND VTE.BatchStatus = @NewBatchStatus
			AND VTE.TaxBasis IS NOT NULL
			AND TaxBasis <> ''
			AND TaxBasis <> @UnknownTaxBasis
			AND VTECD.Id IS NULL
		ORDER BY VTE.ReceivableId

		IF NOT EXISTS (
				SELECT Id
				FROM #ChunkedVertexWSTransactionIds
				)
		BEGIN
			SET @ContinueProcessing = 0;

			BREAK;
		END

		INSERT INTO VertexWSTransactionChunksExtract (
			BatchStatus,
			TaskChunkServiceInstanceId,
			JobStepInstanceId
			)
		VALUES (
			@NewBatchStatus,
			NULL,
			@JobStepInstanceId
			)

		SET @ScopeIdentity = Scope_Identity();

		INSERT INTO VertexWSTransactionChunkDetailsExtract (
			VertexWSTransactionChunks_ExtractId,
			VertexWSTransactionId,
			JobStepInstanceId
			)
		SELECT @ScopeIdentity,
			Id,
			@JobStepInstanceId
		FROM #ChunkedVertexWSTransactionIds

		TRUNCATE TABLE #ChunkedVertexWSTransactionIds
	END

	DROP TABLE #ChunkedVertexWSTransactionIds
END

GO
