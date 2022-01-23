SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ExtractLateFeeReversalDetailsForReceipt]
(
@CreatedById										BIGINT,
@CreatedTime										DATETIMEOFFSET,
@JobStepInstanceId									BIGINT,
@ReceivableEntityTypeValues_CT						NVARCHAR(10),
@LateFeeType_Other									NVARCHAR(40),
@LateFeeType_Interest								NVARCHAR(40),
@LateFeeEntityTypeValues_Contract					NVARCHAR(40),
@ReceivableBilledStatus_Invoiced					NVARCHAR(40),
@SourceTable_LateFee								NVARCHAR(40),
@ValidateForInvoicedReceivables						BIT,
@ValidateForCashPostedReceivables					BIT,
@ReceiptStatus_Posted								NVARCHAR(40),
@ReceiptStatus_Completed							NVARCHAR(40),
@LateFeeApproachValues_BalanceBased					NVARCHAR(12)
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
CREATE TABLE #AdjustmentInfo
(
ReceivableId	BIGINT NULL,
InvoiceNumber	NVARCHAR(40),
ReceiptNumber	NVARCHAR(40)
);
SELECT
RARD.ContractId,
RARD.InvoiceId,
RARD.ReceiptId,
RARD.ContractType,
R.ReceivedDate,
RI.DueDate,
LFA.Id AssessmentId
INTO #InvoiceInfo
FROM
(
	SELECT
	ContractId,
	InvoiceId,
	ReceiptId,
	ContractType,
	JobStepInstanceId,
	LegalEntityId
	FROM ReceiptReceivableDetails_Extract
	WHERE JobStepInstanceId = @JobStepInstanceId AND InvoiceId IS NOT NULL AND ReceivableDetailIsActive = 1
	AND (AmountApplied != 0 OR TaxApplied != 0)
) RARD
INNER JOIN Receipts_Extract R ON RARD.ReceiptId = R.ReceiptId AND RARD.JobStepInstanceId = R.JobStepInstanceId
INNER JOIN ReceivableInvoices RI ON RARD.InvoiceId = RI.Id
INNER JOIN LateFeeAssessments LFA ON RI.Id = LFA.ReceivableInvoiceId
	AND RARD.ContractId = LFA.ContractId AND LFA.IsActive=1
INNER JOIN LegalEntities LE ON RARD.LegalEntityId = LE.Id
	AND LE.LateFeeApproach = @LateFeeApproachValues_BalanceBased
GROUP BY
RARD.ContractId,
RARD.InvoiceId,
RARD.ReceiptId,
RARD.ContractType,
R.ReceivedDate,
RI.DueDate,
LFA.Id
;
SELECT DISTINCT ContractId INTO #ContractIds FROM #InvoiceInfo
SELECT ContractId, MIN(DueDate) FirstInvoiceDate
INTO #FirstInvoiceInfo
FROM #ContractIds C
JOIN ReceivableInvoiceDetails RID ON C.ContractId = RID.EntityId AND RID.EntityType = @ReceivableEntityTypeValues_CT AND RID.IsActive=1
JOIN ReceivableInvoices RI ON RID.ReceivableInvoiceId = RI.Id AND RI.IsActive=1
GROUP BY ContractId
;
SELECT ContractLateFeeInfo.ContractId
,ContractLateFeeInfo.IsLateFeeTypeInterestOrOther
,CASE WHEN Invoice.DueDate = ContractLateFeeInfo.FirstInvoiceDate
THEN CAST(DATEADD(DAY,ContractLateFeeInfo.InvoiceGraceDaysAtInception,Invoice.DueDate) AS DATE)
ELSE CAST(DATEADD(DAY,ContractLateFeeInfo.InvoiceGraceDays,Invoice.DueDate) AS DATE)
END AS DueDatePastGraceDays
,Invoice.AssessmentId
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
AS ContractLateFeeInfo ON Invoice.ContractId = ContractLateFeeInfo.ContractId
;
;WITH CTE_LateFeeDetail AS
(
SELECT
Invoice.InvoiceId
,Invoice.ContractId
,Invoice.ReceiptId
,Invoice.ReceivedDate
,CAST(DATEADD(DAY,1,ISNULL(MIN(LFR.DueDate), Invoice.ReceivedDate)) AS DATE) ReverseFromDate
FROM #InvoiceInfo Invoice
LEFT JOIN LateFeeReceivables LFR ON Invoice.InvoiceId = LFR.ReceivableInvoiceId AND LFR.EntityId = Invoice.ContractId
AND LFR.EntityType = @LateFeeEntityTypeValues_Contract AND LFR.IsActive=1
AND LFR.DueDate > Invoice.ReceivedDate AND LFR.IsManuallyAssessed = 0
GROUP BY Invoice.InvoiceId,Invoice.ContractId,Invoice.ReceiptId, Invoice.ReceivedDate
)
SELECT
LFR.Id LateFeeReceivableId
,LFA.InvoiceDueDate
,LFA.AssessmentId
,R.Id ReceivableId
,LFA.ContractId
,LFA.InvoiceId
,LFR.ReceivableAmendmentType
,CASE WHEN R.TotalAmount_Amount <> R.TotalBalance_Amount THEN 1 ELSE 0 END AS IsCashPosted
,CASE WHEN RD.BilledStatus = @ReceivableBilledStatus_Invoiced THEN 1 ELSE 0 END AS IsInvoiced
,LateFeeDetail.ReceiptId
,LFA.ContractType
,LFR.Amount_Currency CurrencyCode
,LFR.StartDate
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
SELECT ContractId,ReceiptId,ContractType,CurrencyCode,ReceivableId
INTO #InvoicedLateFeeReceivablesTemp
FROM #LateFeeReceivableReversalInfo WHERE IsInvoiced = 1;
WHILE((SELECT COUNT(ContractId) FROM #InvoicedLateFeeReceivablesTemp) > 0)
BEGIN
SELECT
LFR.Id LateFeeReceivableId
,RI.DueDate InvoiceDueDate
,LFA.Id AssessmentId
,Receivables.Id ReceivableId
,LFRR.ContractId
,RI.Id InvoiceId
,LFR.ReceivableAmendmentType
,CASE WHEN Receivables.TotalAmount_Amount <> Receivables.TotalBalance_Amount THEN 1 ELSE 0 END AS IsCashPosted
,CASE WHEN LRD.BilledStatus = @ReceivableBilledStatus_Invoiced THEN 1 ELSE 0 END AS IsInvoiced
,LFRR.ReceiptId
,LFRR.ContractType
,LFRR.CurrencyCode
,LFR.StartDate
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
SELECT ContractId,ReceiptId,ContractType,CurrencyCode,ReceivableId
FROM #AssociatedLateFeeReceivables
WHERE IsInvoiced = 1
DROP TABLE #AssociatedLateFeeReceivables
END
IF(@ValidateForInvoicedReceivables = 1 AND (SELECT COUNT(*) FROM #LateFeeReceivableReversalInfo WHERE IsInvoiced = 1) > 0)
BEGIN
INSERT INTO #AdjustmentInfo
SELECT
LFR.ReceivableId, ReceivableInvoices.Number AS InvoiceNumber, CAST(NULL AS NVARCHAR(40)) AS ReceiptNumber
FROM #LateFeeReceivableReversalInfo LFR
JOIN ReceivableDetails ON LFR.ReceivableId = ReceivableDetails.ReceivableId AND LFR.IsInvoiced = 1 AND ReceivableDetails.IsActive=1
JOIN ReceivableInvoiceDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id AND ReceivableInvoiceDetails.IsActive=1
JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive=1
GROUP BY LFR.ReceivableId,ReceivableInvoices.Number
END
IF(@ValidateForCashPostedReceivables = 1)
BEGIN
UPDATE #LateFeeReceivableReversalInfo
SET IsCashPosted = 1
FROM #LateFeeReceivableReversalInfo LFR
JOIN ReceivableTaxes ON LFR.ReceivableId = ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1 AND ReceivableTaxes.Amount_Amount <> ReceivableTaxes.Balance_Amount
WHERE LFR.IsCashPosted = 0
IF ((SELECT COUNT(*) FROM #LateFeeReceivableReversalInfo WHERE IsCashPosted = 1) > 0)
BEGIN
INSERT INTO #AdjustmentInfo(ReceivableId, ReceiptNumber)
SELECT LFR.ReceivableId, Receipts.Number
FROM #LateFeeReceivableReversalInfo LFR
JOIN ReceivableDetails ON LFR.IsCashPosted = 1 AND LFR.ReceivableId = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive=1
JOIN ReceiptApplicationReceivableDetails ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId AND ReceiptApplicationReceivableDetails.IsActive=1
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id AND Receipts.Status IN (@ReceiptStatus_Completed, @ReceiptStatus_Posted)
GROUP BY LFR.ReceivableId,Receipts.Number
HAVING SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) <> 0 OR SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) <> 0
END
END
SELECT
Assessments.AssessmentId
,MAX(LFR.EndDate) AS AssessedTillDate
INTO #LateFeeAssessedTillDate
FROM
(
SELECT
InvoiceId,AssessmentId,ContractId, MIN(StartDate) MinStartDate
FROM #LateFeeReceivableReversalInfo
GROUP BY InvoiceId,AssessmentId,ContractId
) AS Assessments
INNER JOIN LateFeeReceivables  LFR
ON Assessments.InvoiceId = LFR.ReceivableInvoiceId
AND Assessments.ContractId = LFR.EntityId
AND LFR.EntityType = @LateFeeEntityTypeValues_Contract
AND LFR.IsActive=1 AND LFR.IsManuallyAssessed = 0
AND LFR.EndDate < MinStartDate
GROUP BY Assessments.AssessmentId
INSERT INTO ReceiptLateFeeReversalDetails_Extract
(ReceiptId, ContractId, LateFeeReceivableId, ReceivableId,InvoiceId, ReceiptNumbers, InvoiceNumbers, JobStepInstanceId, CreatedById, CreatedTime,
AssessedTillDate, AssessmentId, ContractType, ReceivableAmendmentType, CurrencyCode)
SELECT
LFR.ReceiptId
,LFR.ContractId
,LFR.LateFeeReceivableId
,LFR.ReceivableId
,LFR.InvoiceId
,CASE WHEN CashPostedReceivables.ReceivableId IS NULL THEN NULL
ELSE STUFF((SELECT ', ' + ReceiptNumber FROM #AdjustmentInfo AdjustmentInfo
WHERE AdjustmentInfo.ReceivableId = LFR.ReceivableId AND AdjustmentInfo.ReceiptNumber IS NOT NULL
FOR XML PATH('')), 1, 2, '')
END AS ReceiptNumbers
,CASE WHEN InvoicedReceivables.ReceivableId IS NULL THEN NULL
ELSE STUFF((SELECT ', ' + InvoiceNumber FROM #AdjustmentInfo AdjustmentInfo
WHERE AdjustmentInfo.ReceivableId = LFR.ReceivableId AND AdjustmentInfo.InvoiceNumber IS NOT NULL
FOR XML PATH('')), 1, 2, '')
END AS InvoiceNumbers
,@JobStepInstanceId
,@CreatedById
,@CreatedTime
,ISNULL(LFA.AssessedTillDate, LFR.InvoiceDueDate)
,LFR.AssessmentId
,LFR.ContractType
,LFR.ReceivableAmendmentType
,LFR.CurrencyCode
FROM #LateFeeReceivableReversalInfo LFR
LEFT JOIN (SELECT AdjustmentInfo.ReceivableId FROM #AdjustmentInfo AdjustmentInfo WHERE AdjustmentInfo.InvoiceNumber IS NOT NULL GROUP BY AdjustmentInfo.ReceivableId) AS InvoicedReceivables ON LFR.ReceivableId = InvoicedReceivables.ReceivableId
LEFT JOIN (SELECT AdjustmentInfo.ReceivableId FROM #AdjustmentInfo AdjustmentInfo WHERE AdjustmentInfo.ReceiptNumber IS NOT NULL GROUP BY AdjustmentInfo.ReceivableId) AS CashPostedReceivables ON LFR.ReceivableId = CashPostedReceivables.ReceivableId
LEFT JOIN #LateFeeAssessedTillDate LFA ON LFR.AssessmentId = LFA.AssessmentId
END

GO
