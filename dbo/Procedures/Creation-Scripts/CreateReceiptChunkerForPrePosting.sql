SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateReceiptChunkerForPrePosting]
(
@ReceiptBatchStatus_New	NVARCHAR(40),
@BatchSize				BIGINT,
@JobStepInstanceId		BIGINT,
@CreatedById			BIGINT,
@CreatedTime			DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SELECT
Receipts_Extract.Id ReceiptExtractId,
((ROW_NUMBER() OVER(ORDER BY Receipts_Extract.Id)) - 1) / @BatchSize + 1 AS BatchNumber
INTO #ReceiptIdBatchDetails
FROM Receipts_Extract
WHERE JobStepInstanceId = @JobStepInstanceId
INSERT INTO ReceiptChunkerForPrePosting_Extract
(FromReceiptExtractId, ToReceiptExtractId, BatchStatus, JobStepInstanceId, BatchNumber, CreatedById, CreatedTime)
SELECT
MIN(ReceiptExtractId)
,MAX(ReceiptExtractId)
,@ReceiptBatchStatus_New
,@JobStepInstanceId
,BatchNumber
,@CreatedById
,@CreatedTime
FROM #ReceiptIdBatchDetails
GROUP BY BatchNumber
END

GO
