SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[CreateChunksForInvoiceGenerationForExternalModules]
(
	@JobStepInstanceId										BIGINT,
	@CreatedById											BIGINT,
	@CreatedTime											DATETIMEOFFSET
)
AS 
BEGIN

	SELECT BillToId, COUNT(BillToId) AS ReceivableDetailsCount 
	INTO #BillToChunk
	FROM InvoiceReceivableDetails_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND IsActive=1
	GROUP BY BillToId

	INSERT INTO InvoiceChunkDetails_Extract(
		BillToId,
		ChunkNumber,
		GenerateStatementInvoice,
		JobStepInstanceId,
		ReceivableDetailsCount,
		CreatedById,
		CreatedTime
	)
	SELECT 
		C.BillToId,
		1,
		0,
		@JobStepInstanceId,
		C.ReceivableDetailsCount,
		@CreatedById,
		@CreatedTime
	FROM #BillToChunk C

	DROP TABLE #BillToChunk
END

GO
