SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateReceiptBatchFromJob]
(
@ReceiptBatchIds IdCollection READONLY,
@ReceiptStatusValues_Posted NVARCHAR(15),
@ReceiptStatusValues_ReadyForPosting NVARCHAR(15),
@ReceiptBatchStatusValues_PartiallyPosted NVARCHAR(15),
@ReceiptPostingFailedMessage NVARCHAR(400),
@JobStepInstanceId BIGINT,
@PostDate DATE,
@UpdatedById BigInt,
@UpdatedTime DateTimeOffset
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE ReceiptBatchDetails
SET Comment = CASE WHEN Receipts.Status = @ReceiptStatusValues_ReadyForPosting THEN @ReceiptPostingFailedMessage ELSE NULL END,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM ReceiptBatchDetails
INNER JOIN @ReceiptBatchIds Batch ON ReceiptBatchDetails.ReceiptBatchId = Batch.Id AND ReceiptBatchDetails.IsActive = 1
INNER JOIN Receipts ON ReceiptBatchDetails.ReceiptId = Receipts.Id
;WITH CTE_FailedReceipts(ReceiptId) AS
(
SELECT ReceiptId FROM Receipts_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND IsValid = 0
)
UPDATE Receipts
SET JobStepInstanceId = @JobStepInstanceId,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM Receipts
JOIN CTE_FailedReceipts ON Receipts.Id = CTE_FailedReceipts.ReceiptId
;WITH CTE_BatchWithPostedReceipts AS
(
SELECT Batch.Id BatchId,SUM(Receipts.ReceiptAmount_Amount) TotalReceiptAmount
FROM @ReceiptBatchIds Batch
INNER JOIN ReceiptBatchDetails ON Batch.Id = ReceiptBatchDetails.ReceiptBatchId AND ReceiptBatchDetails.IsActive = 1
INNER JOIN Receipts ON ReceiptBatchDetails.ReceiptId = Receipts.Id AND Receipts.Status <> @ReceiptStatusValues_ReadyForPosting
GROUP BY Batch.Id
)
UPDATE ReceiptBatches
SET Status = CASE WHEN BatchWithFailedReceipts.Id IS NULL THEN @ReceiptStatusValues_Posted ELSE @ReceiptBatchStatusValues_PartiallyPosted END,
IsPartiallyPosted = CASE WHEN BatchWithFailedReceipts.Id IS NULL THEN 0 ELSE 1 END,
ReceiptAmountAlreadyPosted_Amount = ISNULL(CTE_BatchWithPostedReceipts.TotalReceiptAmount,0.00),
PostDate = @PostDate,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM ReceiptBatches
INNER JOIN @ReceiptBatchIds Batch ON ReceiptBatches.Id = Batch.Id
INNER JOIN CTE_BatchWithPostedReceipts ON Batch.Id = CTE_BatchWithPostedReceipts.BatchId
LEFT JOIN
(
SELECT Batch.Id
FROM @ReceiptBatchIds Batch
INNER JOIN Receipts ON Batch.Id = Receipts.ReceiptBatchId AND Receipts.Status = @ReceiptStatusValues_ReadyForPosting
GROUP BY Batch.Id
) AS BatchWithFailedReceipts ON Batch.Id = BatchWithFailedReceipts.Id
END

GO
