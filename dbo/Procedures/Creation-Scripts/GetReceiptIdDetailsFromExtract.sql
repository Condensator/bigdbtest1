SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetReceiptIdDetailsFromExtract]
(
@JobStepInstanceId						BIGINT,
@ReceiptBatchExtractStatus_New			NVARCHAR(40),
@ReceiptBatchExtractStatus_Processing	NVARCHAR(40),
@TaskChunkServiceInstanceId				BIGINT NULL,
@CreatedById							BIGINT,
@CreatedTime							DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

CREATE TABLE #ChunkedBatchId(
Id BIGINT
)

UPDATE TOP(1) ReceiptChunkerForPosting_Extract
SET PrePostingBatchStatus = @ReceiptBatchExtractStatus_Processing,
PrePostingStartTime = @CreatedTime,
PrePostingTaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
OUTPUT INSERTED.Id INTO #ChunkedBatchId
WHERE JobStepInstanceId = @JobStepInstanceId AND PrePostingBatchStatus = @ReceiptBatchExtractStatus_New

SELECT RCFP.ReceiptId, RCFP.Id
FROM ReceiptChunkerForPostingDetail_Extract RCFP WITH (NOLOCK)
JOIN Receipts_Extract RE WITH (NOLOCK) ON RCFP.ReceiptId = RE.ReceiptId
AND RE.JobStepInstanceId = @JobStepInstanceId AND RE.IsValid = 1
WHERE RCFP.JobStepInstanceId = @JobStepInstanceId
AND RCFP.ReceiptChunkerForPosting_ExtractId = (SELECT TOP 1 Id from #ChunkedBatchId)

SELECT TOP 1 Id from #ChunkedBatchId

SELECT SourceModule FROM ReceiptChunkerForPosting_Extract WHERE Id IN (SELECT TOP 1 Id from #ChunkedBatchId)

END

GO
