SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ValidateLateFeeReversalDetailsForACH]
(
@JobStepInstanceId									BIGINT,
@ReceivableEntityTypeValues_CT						NVARCHAR(10),
@LateFeeType_Other									NVARCHAR(40),
@LateFeeType_Interest								NVARCHAR(40),
@LateFeeEntityTypeValues_Contract					NVARCHAR(40),
@ReceivableBilledStatus_Invoiced					NVARCHAR(40),
@SourceTable_LateFee								NVARCHAR(40),
@LateFeeApproachValues_BalanceBased					NVARCHAR(40),
@ReceiptStatusPending								NVARCHAR(40),
@ErrorCode											NVARCHAR(40)
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;

SELECT
ACHExtract.ContractId AS ContractId,
RI.Id AS InvoiceId,
ACHExtract.ContractType AS ContractType,
ACHExtract.SettlementDate AS ReceivedDate,
RI.DueDate
INTO #InvoiceInfo
FROM  ACHSchedule_Extract ACHExtract 
INNER JOIN ReceivableInvoiceDetails RID ON RID.ReceivableDetailId = ACHExtract.ReceivableDetailId AND RID.IsACtive = 1 
INNER JOIN ReceivableInvoices RI ON RID.ReceivableInvoiceId = RI.Id AND RI.IsActive = 1
INNER JOIN LateFeeAssessments LFA ON RI.Id = LFA.ReceivableInvoiceId
	AND ACHExtract.ContractId = LFA.ContractId AND LFA.IsActive=1
INNER JOIN LegalEntities LE ON ACHExtract.ReceiptLegalEntityId = LE.Id
	AND LE.LateFeeApproach = @LateFeeApproachValues_BalanceBased
	WHERE (ACHExtract.ErrorCode IS NULL OR ACHExtract.ErrorCode ='_') AND ACHExtract.JobStepInstanceId = @JObStepInstanceId
GROUP BY
ACHExtract.ContractId,
RI.Id,
ACHExtract.ContractType,
ACHExtract.SettlementDate,
RI.DueDate
;

SELECT DISTINCT ContractId INTO #ContractIds FROM #InvoiceInfo

SELECT ContractId, MIN(DueDate) FirstInvoiceDate
INTO #FirstInvoiceInfo
FROM #ContractIds C
JOIN ReceivableInvoiceDetails RID ON C.ContractId = RID.EntityId AND RID.EntityType = @ReceivableEntityTypeValues_CT AND RID.IsActive=1
JOIN ReceivableInvoices RI ON RID.ReceivableInvoiceId = RI.Id AND RI.IsActive=1
GROUP BY ContractId;


SELECT ContractLateFeeInfo.ContractId
,ContractLateFeeInfo.IsLateFeeTypeInterestOrOther
,CASE WHEN Invoice.DueDate = ContractLateFeeInfo.FirstInvoiceDate
THEN CAST(DATEADD(DAY,ContractLateFeeInfo.InvoiceGraceDaysAtInception,Invoice.DueDate) AS DATE)
ELSE CAST(DATEADD(DAY,ContractLateFeeInfo.InvoiceGraceDays,Invoice.DueDate) AS DATE)
END AS DueDatePastGraceDays
,Invoice.DueDate InvoiceDueDate
,Invoice.ContractType
,Invoice.InvoiceId
INTO #LateFeeAssessmentInfo
FROM #InvoiceInfo Invoice
INNER JOIN
(
SELECT
C.ContractId
,CLF.InvoiceGraceDays
,CLF.InvoiceGraceDaysAtInception
,CASE WHEN LFT.LateFeeType = @LateFeeType_Interest OR LFT.LateFeeType = @LateFeeType_Other
THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT)
END AS IsLateFeeTypeInterestOrOther
,FI.FirstInvoiceDate
FROM #ContractIds C
INNER JOIN ContractLateFees CLF ON C.ContractId = CLF.Id
INNER JOIN LateFeeTemplates LFT ON CLF.LateFeeTemplateId = LFT.Id
INNER JOIN #FirstInvoiceInfo FI ON C.ContractId = FI.ContractId
)
AS ContractLateFeeInfo ON Invoice.ContractId = ContractLateFeeInfo.ContractId;

;WITH CTE_LateFeeDetail AS
(
SELECT
Invoice.InvoiceId
,Invoice.ContractId
,Invoice.ReceivedDate
,CAST(DATEADD(DAY,1,ISNULL(MIN(LFR.DueDate), Invoice.ReceivedDate)) AS DATE) ReverseFromDate
FROM #InvoiceInfo Invoice
LEFT JOIN LateFeeReceivables LFR ON Invoice.InvoiceId = LFR.ReceivableInvoiceId AND LFR.EntityId = Invoice.ContractId
AND LFR.EntityType = @LateFeeEntityTypeValues_Contract AND LFR.IsActive=1
AND LFR.DueDate > Invoice.ReceivedDate AND LFR.IsManuallyAssessed = 0
GROUP BY Invoice.InvoiceId,Invoice.ContractId,Invoice.ReceivedDate
)
SELECT
LFR.Id LateFeeReceivableId
,LFA.InvoiceDueDate
,R.Id ReceivableId
,LFA.ContractId
,LFA.InvoiceId
,LFR.ReceivableAmendmentType
,CASE WHEN R.TotalAmount_Amount <> R.TotalBalance_Amount THEN 1 ELSE 0 END AS IsCashPosted
,CASE WHEN RD.BilledStatus = @ReceivableBilledStatus_Invoiced THEN 1 ELSE 0 END AS IsInvoiced
,LFA.ContractType
,LFR.Amount_Currency CurrencyCode
,LFR.StartDate
,RD.Id AS ReceivableDetailId
INTO #LateFeeReceivableReversalInfo
FROM #LateFeeAssessmentInfo LFA
INNER JOIN CTE_LateFeeDetail AS LateFeeDetail ON LFA.InvoiceId = LateFeeDetail.InvoiceId
AND LFA.ContractId = LateFeeDetail.ContractId
INNER JOIN LateFeeReceivables LFR ON LFA.InvoiceId = LFR.ReceivableInvoiceId AND LFA.ContractId = LFR.EntityId
AND LFR.EntityType = @LateFeeEntityTypeValues_Contract AND LFR.IsActive=1 AND LFR.IsManuallyAssessed = 0
INNER JOIN Receivables R ON LFR.Id = R.SourceId AND R.SourceTable = @SourceTable_LateFee AND R.IsActive=1
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId AND RD.IsActive=1
WHERE
(
IsLateFeeTypeInterestOrOther = 0 AND
(
(DueDatePastGraceDays < LateFeeDetail.ReceivedDate AND LFR.DueDate >= ReverseFromDate)
OR (DueDatePastGraceDays >= LateFeeDetail.ReceivedDate)
)
)
OR
(IsLateFeeTypeInterestOrOther = 1 AND LFR.DueDate >= LateFeeDetail.ReceivedDate);

SELECT ContractId
,ContractType,CurrencyCode,ReceivableId
INTO #InvoicedLateFeeReceivablesTemp
FROM #LateFeeReceivableReversalInfo WHERE IsInvoiced = 1;

WHILE((SELECT COUNT(ContractId) FROM #InvoicedLateFeeReceivablesTemp) > 0)
BEGIN
SELECT
LFR.Id LateFeeReceivableId
,RI.DueDate InvoiceDueDate
,Receivables.Id ReceivableId
,LFRR.ContractId
,RI.Id InvoiceId
,LFR.ReceivableAmendmentType
,CASE WHEN Receivables.TotalAmount_Amount <> Receivables.TotalBalance_Amount THEN 1 ELSE 0 END AS IsCashPosted
,CASE WHEN LRD.BilledStatus = @ReceivableBilledStatus_Invoiced THEN 1 ELSE 0 END AS IsInvoiced
,LFRR.ContractType
,LFRR.CurrencyCode
,LFR.StartDate,
LRD.Id AS ReceivableDetailId
INTO #AssociatedLateFeeReceivables
FROM #InvoicedLateFeeReceivablesTemp LFRR
JOIN ReceivableDetails RD ON LFRR.ReceivableId = RD.ReceivableId AND RD.BilledStatus = @ReceivableBilledStatus_Invoiced AND RD.IsActive=1
JOIN ReceivableInvoiceDetails RID ON RD.Id = RID.ReceivableDetailId AND RID.IsActive=1
JOIN ReceivableInvoices RI ON RI.Id = RID.ReceivableInvoiceId AND RI.IsActive=1
JOIN LateFeeReceivables LFR ON RI.Id = LFR.ReceivableInvoiceId AND LFR.EntityType = @LateFeeEntityTypeValues_Contract
AND LFR.EntityId = LFRR.ContractId
AND LFR.IsActive=1 AND LFR.IsManuallyAssessed = 0
JOIN LateFeeAssessments LFA ON LFR.EntityId = LFA.ContractId AND LFR.ReceivableInvoiceId = LFA.ReceivableInvoiceId AND LFA.IsActive=1
JOIN Receivables ON LFR.Id = Receivables.SourceId AND Receivables.SourceTable = @SourceTable_LateFee AND Receivables.IsActive=1
JOIN ReceivableDetails LRD ON Receivables.Id = LRD.ReceivableId AND LRD.IsActive=1;
INSERT INTO #LateFeeReceivableReversalInfo
SELECT * FROM #AssociatedLateFeeReceivables
DELETE FROM #InvoicedLateFeeReceivablesTemp
INSERT INTO #InvoicedLateFeeReceivablesTemp
SELECT ContractId
,ContractType,CurrencyCode,ReceivableId
FROM #AssociatedLateFeeReceivables
WHERE IsInvoiced = 1
DROP TABLE #AssociatedLateFeeReceivables
END


UPDATE ACHExtract SET ErrorCode = @ErrorCode
FROM  ACHSchedule_Extract ACHExtract 
JOIN #LateFeeReceivableReversalInfo LFR ON  LFR.ReceivableId = ACHExtract.ReceivableId
AND JobStepInstanceId= @JobstepInstanceId AND (ErrorCode IS NULL OR ErrorCode ='_')


SELECT RID.ReceivableDetailId,R.Id AS ReceivableId 
INTO #ReceivableInvoiceDetails 
FROM AchSchedule_Extract ACH
JOIN Receivables R ON ACH.ReceivableId = R.Id AND R.SourceTable = @SourceTable_LateFee AND R.IsActive=1
JOIN LateFeeReceivables LFR ON LFR.Id = R.SourceId AND LFR.IsActive=1
JOIN ReceivableInvoiceDetails RID ON RID.ReceivableInvoiceId = LFR.ReceivableInvoiceId AND RID.IsActive = 1
WHERE JobStepInstanceId= @JobstepInstanceId
GROUP BY RID.ReceivableDetailId , R.Id

SELECT  RDIds.ReceivableId  INTO #ReceivableIds 
FROM ACHReceipts ACHR
JOIN ACHReceiptApplicationReceivableDetails ACHRARD ON ACHR.Id = ACHRARD.AChReceiptId 
JOIN #ReceivableInvoiceDetails RDIds ON RDIds.ReceivableDetailId = ACHRARD.ReceivableDetailId
WHERE (ACHR.ReceiptId IS NULL OR ACHR.ReceiptId < 0)AND ACHR.IsActive = 1
GROUP BY RDIds.ReceivableId

INSERT INTO #ReceivableIds 
SELECT  RDIds.ReceivableId  
FROM ACHReceipts ACHR
JOIN ACHReceiptApplicationReceivableDetails ACHRARD ON ACHR.Id = ACHRARD.AChReceiptId 
JOIN #ReceivableInvoiceDetails RDIds ON RDIds.ReceivableDetailId = ACHRARD.ReceivableDetailId
JOIN Receipts R ON R.Id= ACHR.ReceiptID AND ACHR.ReceiptId IS NOT NULL AND  ACHR.ReceiptId > 0
WHERE ACHR.Status = @ReceiptStatusPending  AND ACHR.IsActive = 1
AND R.Status =@ReceiptStatusPending
GROUP BY RDIds.ReceivableId

UPDATE ACHExtract SET ErrorCode =@ErrorCode
FROM  ACHSchedule_Extract ACHExtract
JOIN #ReceivableIds R ON  R.ReceivableId = ACHExtract.ReceivableId
AND JobStepInstanceId= @JobStepInstanceId AND (ErrorCode IS NULL OR ERRORCODE ='_')

END

GO
