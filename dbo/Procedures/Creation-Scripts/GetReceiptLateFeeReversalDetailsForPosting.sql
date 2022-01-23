SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetReceiptLateFeeReversalDetailsForPosting]
(
@ReceiptIds			IdCollection	READONLY,
@JobStepInstanceId					BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
SELECT Id INTO #ReceiptIds FROM @ReceiptIds
SELECT
RLRD.ReceiptId
,RLRD.ContractId
,RLRD.CurrencyCode
,RLRD.ReceivableId
,RLRD.LateFeeReceivableId
,RLRD.AssessmentId
,RLRD.AssessedTillDate
,RLRD.ContractType
,RLRD.ReceivableAmendmentType
FROM #ReceiptIds AS ReceiptIds
JOIN ReceiptLateFeeReversalDetails_Extract RLRD ON RLRD.ReceiptId = ReceiptIds.Id AND
RLRD.JobStepInstanceId = @JobStepInstanceId
DROP TABLE #ReceiptIds
END

GO
