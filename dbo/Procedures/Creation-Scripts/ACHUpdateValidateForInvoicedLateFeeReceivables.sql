SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ACHUpdateValidateForInvoicedLateFeeReceivables]
(
@JobStepInstanceId BIGINT,
@AdjustReceivableIfInvoiced BIT,
@ErrorCode NVARCHAR(4),
@LateFeeSourceTable NVARCHAR(30)
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
SELECT  OneTimeACHId,ACHScheduleId,R.Id AS ReceivableId
INTO #CTE_LateFeeSchedules
FROM  CTE_ReceivableDetails RD
JOIN ReceivableInvoiceDetails RID ON RD.ReceivableDetailId = RID.ReceivableDetailId AND RID.IsActive = 1
JOIN ReceivableInvoices RI ON RID.ReceivableInvoiceId = RI.Id AND RI.IsActive = 1
JOIN LateFeeReceivables LFR ON RID.ReceivableInvoiceId = LFR.ReceivableInvoiceId AND LFR.IsActive = 1
JOIN Receivables R ON LFR.Id = R.SourceId AND R.SourceTable = @LateFeeSourceTable AND R.IsActive = 1
WHERE @AdjustReceivableIfInvoiced = 0 AND RD.SettlementDate <= RI.DueDate 
GROUP BY OneTimeACHId,ACHScheduleId,R.Id

SELECT ReceivableId INTO #CTE_LateFeeReceivableIDs FROM #CTE_LateFeeSchedules
GROUP BY ReceivableId

SELECT #CTE_LateFeeReceivableIDs.ReceivableId,RIs.Number
INTO #CTE_InvalidReceivableIds
FROM #CTE_LateFeeReceivableIDs
JOIN ReceivableDetails RDs ON Rds.ReceivableId = #CTE_LateFeeReceivableIDs.ReceivableId AND Rds.IsActive=1 AND RDs.BilledStatus = 'Invoiced'
JOIN ReceivableInvoiceDetails RIDs ON RIds.ReceivableDetailId = RDs.Id AND RIDs.IsActive=1
JOIN ReceivableInvoices RIs ON RIDs.ReceivableInvoiceId = RIs.Id AND RIs.IsActive = 1

SELECT OneTimeACHId,ACHScheduleId , STRING_AGG(CAST(Number AS NVARCHAR(MAX)), ',') AS InvoiceNumbers
INTO #LateFeeInvoiceReceivableDeailInfos
FROM #CTE_InvalidReceivableIds 
JOIN #CTE_LateFeeSchedules ON #CTE_InvalidReceivableIds.ReceivableId = #CTE_LateFeeSchedules.ReceivableId
GROUP BY OneTimeACHId,ACHScheduleId


Update ACHS SET ErrorCode = @ErrorCode, LateFeeInvoiceNumbers = #LateFeeInvoiceReceivableDeailInfos.InvoiceNumbers 
 FROM ACHSchedule_Extract ACHS
 JOIN #LateFeeInvoiceReceivableDeailInfos ON ACHS.OneTimeACHId = #LateFeeInvoiceReceivableDeailInfos.OneTimeACHId
WHERE ACHS.JobStepInstanceId = @JobStepInstanceId
AND ACHS.ErrorCode = '_'


Update ACHS SET ErrorCode = @ErrorCode, LateFeeInvoiceNumbers = #LateFeeInvoiceReceivableDeailInfos.InvoiceNumbers
 FROM ACHSchedule_Extract ACHS
 JOIN #LateFeeInvoiceReceivableDeailInfos ON ACHS.ACHScheduleId = #LateFeeInvoiceReceivableDeailInfos.ACHScheduleId
WHERE ACHS.JobStepInstanceId = @JobStepInstanceId
AND ACHS.ErrorCode = '_'

END;

GO
