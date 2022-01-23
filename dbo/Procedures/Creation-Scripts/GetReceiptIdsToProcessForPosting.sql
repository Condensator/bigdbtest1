SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetReceiptIdsToProcessForPosting]
(
@JobStepInstanceId						BIGINT,
@ReceiptBatchExtractStatus_New			NVARCHAR(40),
@ReceiptBatchExtractStatus_Processing	NVARCHAR(40),
@ReceiptStatus_Posted                   NVARCHAR(15),
@TaskChunkServiceInstanceId				BIGINT NULL,
@CurrentUserId							BIGINT,
@CurrentTime							DATETIMEOFFSET,
@ChunkedBatchId							BIGINT OUTPUT,
@SourceModule							NVARCHAR(21) OUTPUT
)
AS
BEGIN
SET NOCOUNT ON;

CREATE TABLE #ChunkedBatchId(
Id				BIGINT,
SourceModule	NVARCHAR(21)
)

UPDATE TOP(1) ReceiptChunkerForPosting_Extract
SET PostingBatchStatus = @ReceiptBatchExtractStatus_Processing,
PostingStartTime = @CurrentTime,
PostingTaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
OUTPUT INSERTED.Id, INSERTED.SourceModule INTO #ChunkedBatchId 
WHERE JobStepInstanceId = @JobStepInstanceId AND PostingBatchStatus = @ReceiptBatchExtractStatus_New

SELECT RCFP.ReceiptId AS Id
FROM ReceiptChunkerForPostingDetail_Extract RCFP WITH (NOLOCK) 
JOIN Receipts_Extract RE WITH (NOLOCK) ON RCFP.ReceiptId = RE.ReceiptId
AND RE.JobStepInstanceId = RCFP.JobStepInstanceId AND RE.IsValid = 1
WHERE RCFP.JobStepInstanceId = @JobStepInstanceId
AND RCFP.ReceiptChunkerForPosting_ExtractId = (SELECT TOP 1 Id from #ChunkedBatchId)
AND ((ACHReceiptId IS NOT NULL AND Status = @ReceiptStatus_Posted) OR (ACHReceiptId IS NULL));

SELECT TOP 1 @ChunkedBatchId = Id, @SourceModule = SourceModule FROM #ChunkedBatchId

END

GO
