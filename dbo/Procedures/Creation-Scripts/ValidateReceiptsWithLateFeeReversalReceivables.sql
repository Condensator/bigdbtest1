SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ValidateReceiptsWithLateFeeReversalReceivables]
(
@JobStepInstanceId			BIGINT,
@ReceiptPostingErrorSource_LateFee NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #InvalidReceiptNumber
(
ReceiptNumber	NVARCHAR(100)
)
;WITH CTE_LateFeeReceipts AS
(
SELECT
RARD.ReceiptId
FROM ReceiptReceivableDetails_Extract RARD
INNER JOIN ReceiptLateFeeReversalDetails_Extract LFRD
ON RARD.JobStepInstanceId = LFRD.JobStepInstanceId AND RARD.ReceivableId = LFRD.ReceivableId
WHERE
RARD.JobStepInstanceId = @JobStepInstanceId
)
UPDATE Receipts_Extract
SET IsValid = 0, SourceOfError = @ReceiptPostingErrorSource_LateFee
OUTPUT DELETED.ReceiptNumber INTO #InvalidReceiptNumber
FROM Receipts_Extract R
JOIN CTE_LateFeeReceipts CR ON R.ReceiptId = CR.ReceiptId
WHERE JobStepInstanceId = @JobStepInstanceId
SELECT * FROM #InvalidReceiptNumber;
END

GO
