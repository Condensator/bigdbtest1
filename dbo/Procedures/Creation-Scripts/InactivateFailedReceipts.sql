SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[InactivateFailedReceipts]
(
@JobStepInstanceId		BIGINT,
@CurrentUserId			BIGINT,
@CurrentTime			DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @ReceiptApplicationInformation ReceiptApplicationInfo
DECLARE @False BIT=0
SELECT ReceiptId, ReceiptApplicationId, ReceivedDate
INTO #InvalidFileReceiptInfo
FROM Receipts_Extract
WHERE IsValid=0 AND	ReceiptBatchId IS NULL
AND IsNewReceipt=1 ANd JobStepInstanceId=@JobStepInstanceId

UPDATE Receipts SET
Receipts.[Status]='Inactive'
FROM Receipts INNER JOIN #InvalidFileReceiptInfo
ON Receipts.Id=#InvalidFileReceiptInfo.ReceiptId AND Receipts.JobStepInstanceId=@JobStepInstanceId
UPDATE RARD SET
RARD.IsActive=0,
RARD.AmountApplied_Amount=0.00,
RARD.TaxApplied_Amount=0.00,
BookAmountApplied_Amount=0.00
FROM ReceiptApplicationReceivableDetails RARD
INNER JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId=RA.Id
INNER JOIN #InvalidFileReceiptInfo ON RA.ReceiptId=#InvalidFileReceiptInfo.ReceiptId AND RA.Id=#InvalidFileReceiptInfo.ReceiptApplicationId
UPDATE RAI SET
RAI.IsActive=0
FROM ReceiptApplicationInvoices RAI
INNER JOIN #InvalidFileReceiptInfo ON RAI.ReceiptApplicationId=#InvalidFileReceiptInfo.ReceiptApplicationId
INSERT INTO @ReceiptApplicationInformation
SELECT ReceiptId, ReceiptApplicationId, ReceivedDate
FROM #InvalidFileReceiptInfo
EXEC UpdateEffectiveBalancesFromReceiptPosting @ReceiptApplicationInformation, @CurrentUserId, @CurrentTime, @False, 0
DROP TABLE #InvalidFileReceiptInfo
END

GO
