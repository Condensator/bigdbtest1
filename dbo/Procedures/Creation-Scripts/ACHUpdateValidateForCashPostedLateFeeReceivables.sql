SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateForCashPostedLateFeeReceivables]
(
@JobStepInstanceId BIGINT,
@AdjustReceivableIfCashPosted BIT,
@ErrorCode NVARCHAR(4),
@LateFeeSourceTable NVARCHAR(30),
@PostedStatus NVARCHAR(50)
)
AS
BEGIN
DECLARE @ReceivableIds NVARCHAR(MAX);

;WITH CTE_ReceivableDetails
AS
(
SELECT DISTINCT ReceivableDetailId,OneTimeACHId,ACHScheduleId,SettlementDate FROM ACHSchedule_Extract ACHS
WHERE ACHS.JobStepInstanceId = @JobStepInstanceId
AND ACHS.ErrorCode = '_'
)
,CTE_InvalidSchedules
AS(
SELECT  OneTimeACHId,ACHScheduleId,RT.Number
FROM  CTE_ReceivableDetails ReceivableDetails
JOIN ReceivableInvoiceDetails RID ON ReceivableDetails.ReceivableDetailId = RID.ReceivableDetailId AND RID.IsActive = 1
JOIN ReceivableInvoices RI ON RID.ReceivableInvoiceId = RI.Id AND RI.IsActive = 1
JOIN LateFeeReceivables LFR ON RI.Id = LFR.ReceivableInvoiceId AND LFR.IsActive = 1
JOIN Receivables R ON LFR.Id = R.SourceId AND R.SourceTable = @LateFeeSourceTable AND R.IsActive = 1
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId AND RD.IsActive = 1
JOIN ReceiptApplicationReceivableDetails RARD ON RARD.ReceivableDetailId = RD.Id AND RARD.IsActive = 1
JOIN ReceiptApplications RA ON RA.Id = RARD.ReceiptApplicationId
JOIN Receipts RT ON RT.Id = RA.ReceiptId AND RT.Status = @PostedStatus
WHERE @AdjustReceivableIfCashPosted = 0 AND ReceivableDetails.SettlementDate <= RI.DueDate 
GROUP BY OneTimeACHId,ACHScheduleId,RT.Number
)
SELECT OneTimeACHId,ACHScheduleId , STRING_AGG(CAST(Number AS NVARCHAR(MAX)), ',') AS ReceiptNumbers
INTO #LateFeeInvoiceReceivableDeailInfos
FROM CTE_InvalidSchedules
GROUP BY OneTimeACHId,ACHScheduleId


Update ACHS SET ErrorCode = @ErrorCode, LateFeeReceiptIds = #LateFeeInvoiceReceivableDeailInfos.ReceiptNumbers
 FROM ACHSchedule_Extract ACHS
 JOIN #LateFeeInvoiceReceivableDeailInfos ON ACHS.OneTimeACHId = #LateFeeInvoiceReceivableDeailInfos.OneTimeACHId
WHERE ACHS.JobStepInstanceId = @JobStepInstanceId
AND ACHS.ErrorCode = '_'


Update ACHS SET ErrorCode = @ErrorCode, LateFeeReceiptIds = #LateFeeInvoiceReceivableDeailInfos.ReceiptNumbers 
 FROM ACHSchedule_Extract ACHS
 JOIN #LateFeeInvoiceReceivableDeailInfos ON ACHS.ACHScheduleId = #LateFeeInvoiceReceivableDeailInfos.ACHScheduleId
WHERE ACHS.JobStepInstanceId = @JobStepInstanceId
AND ACHS.ErrorCode = '_'

END;

GO
