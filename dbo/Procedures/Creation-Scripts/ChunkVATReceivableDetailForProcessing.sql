SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ChunkVATReceivableDetailForProcessing] (
	@BatchCount BIGINT,
	@NewBatchStatus NVARCHAR(10),
	@JobStepInstanceId BIGINT,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET
	)
AS
BEGIN
	CREATE TABLE #ChunkedVATReceivableDetailIds (Id BIGINT)

	DECLARE @ContinueProcessing BIT = 1;
	DECLARE @ScopeIdentity BIGINT;

	WHILE @ContinueProcessing = 1
	BEGIN
		INSERT INTO #ChunkedVATReceivableDetailIds
		SELECT TOP (@BatchCount)
		WITH TIES VTE.Id
		FROM VATReceivableDetailExtract VTE
		LEFT JOIN VATReceivableDetailChunkDetailsExtract VTECD ON VTE.Id = VTECD.VATReceivableDetail_ExtractId
			AND VTECD.JobStepInstanceId = @JobStepInstanceId
		WHERE VTE.JobStepInstanceId = @JobStepInstanceId
			AND VTE.BatchStatus = @NewBatchStatus
			AND VTECD.Id IS NULL
		ORDER BY VTE.ReceivableId

		IF NOT EXISTS (
				SELECT Id
				FROM #ChunkedVATReceivableDetailIds
				)
		BEGIN
			SET @ContinueProcessing = 0;

			BREAK;
		END

		INSERT INTO VATReceivableDetailChunkExtract (
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

		INSERT INTO VATReceivableDetailChunkDetailsExtract (
			VATReceivableDetailChunk_ExtractId,
			VATReceivableDetail_ExtractId,
			JobStepInstanceId
			)
		SELECT @ScopeIdentity,
			Id,
			@JobStepInstanceId
		FROM #ChunkedVATReceivableDetailIds

		TRUNCATE TABLE #ChunkedVATReceivableDetailIds
	END

	DROP TABLE #ChunkedVATReceivableDetailIds
END

GO
