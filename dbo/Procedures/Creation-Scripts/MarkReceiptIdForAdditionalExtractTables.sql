SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[MarkReceiptIdForAdditionalExtractTables]
(
@JobStepInstanceId		BIGINT,
@CurrentUserId			BIGINT,
@CurrentTime			DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE R SET
R.ReceiptId = RE.ReceiptId,
R.ReceiptApplicationReceivableDetailId = RRD.ReceiptApplicationReceivableDetailId,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceiptOTPReceivables_Extract R
INNER JOIN Receipts_Extract RE ON R.JobStepInstanceId=@JobStepInstanceId AND R.ReceiptId=RE.BeforePostingReceiptId AND R.JobStepInstanceId=RE.JobStepInstanceId AND RE.IsValid=1
INNER JOIN ReceiptReceivableDetails_Extract RRD ON RRD.JobStepInstanceId=@JobStepInstanceId AND RRD.ReceiptId=RE.ReceiptId AND R.ReceivableDetailId=RRD.ReceivableDetailId
UPDATE ReceiptLateFeeReversalDetails_Extract
SET ReceiptLateFeeReversalDetails_Extract.ReceiptId = Receipts_Extract.ReceiptId,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceiptLateFeeReversalDetails_Extract INNER JOIN Receipts_Extract
ON ReceiptLateFeeReversalDetails_Extract.JobStepInstanceId = Receipts_Extract.JobStepInstanceId
AND ReceiptLateFeeReversalDetails_Extract.ReceiptId = Receipts_Extract.BeforePostingReceiptId
WHERE Receipts_Extract.IsValid = 1 AND Receipts_Extract.JobStepInstanceId=@JobStepInstanceId
UPDATE ReceiptUpfrontTaxDetails_Extract
SET ReceiptUpfrontTaxDetails_Extract.ReceiptId = Receipts_Extract.ReceiptId,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceiptUpfrontTaxDetails_Extract INNER JOIN Receipts_Extract
ON ReceiptUpfrontTaxDetails_Extract.JobStepInstanceId = Receipts_Extract.JobStepInstanceId
AND ReceiptUpfrontTaxDetails_Extract.ReceiptId = Receipts_Extract.BeforePostingReceiptId
WHERE Receipts_Extract.IsValid = 1 AND Receipts_Extract.JobStepInstanceId=@JobStepInstanceId
UPDATE ReceiptRentSharingDetails_Extract
SET ReceiptRentSharingDetails_Extract.ReceiptId = Receipts_Extract.ReceiptId,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceiptRentSharingDetails_Extract INNER JOIN Receipts_Extract
ON ReceiptRentSharingDetails_Extract.JobStepInstanceId = Receipts_Extract.JobStepInstanceId
AND ReceiptRentSharingDetails_Extract.ReceiptId = Receipts_Extract.BeforePostingReceiptId
WHERE Receipts_Extract.IsValid = 1 AND Receipts_Extract.JobStepInstanceId=@JobStepInstanceId
END

GO
