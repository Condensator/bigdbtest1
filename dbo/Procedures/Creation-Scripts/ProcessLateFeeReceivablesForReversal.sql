SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ProcessLateFeeReceivablesForReversal]
(
@ProcessThroughDate DATE,
@InvoiceInfo InvoiceInfo READONLY,
@ValidateForInvoicedReceivables BIT,
@ValidateForCashPostedReceivables BIT,
@ReversedDate DATE,
@UpdatedTime DATETIMEOFFSET,
@UpdatedById BIGINT,
@ReceivableIdsInCurrentReceipt LateFeeReceivableIdTemp READONLY,
@ReceiptNumber NVARCHAR(40) = NULL,
@CanUpdate BIT
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @ContractIds TABLE(ContractId BIGINT);
DECLARE @LateFeeReceivableReversalInfo TABLE(LateFeeReceivableId BIGINT,InvoiceDueDate DATE,InstrumentTypeId BIGINT,LineofBusinessId BIGINT,CostCenterId BIGINT,AssessmentId BIGINT,ReceivableId BIGINT, ContractType NVARCHAR(28),ContractId BIGINT,InvoiceId BIGINT,ReceivableAmendmentType NVARCHAR(40),IsCashPosted BIT, IsInvoiced BIT)
DECLARE @FirstInvoiceInfo TABLE (ContractId BIGINT,FirstInvoiceDate DATE);
INSERT INTO @ContractIds
SELECT ContractId FROM @InvoiceInfo GROUP BY ContractId;
INSERT INTO @FirstInvoiceInfo
SELECT C.ContractId,MIN(ReceivableInvoices.DueDate) FirstInvoiceDate
FROM @ContractIds C
JOIN ReceivableInvoiceDetails ON C.ContractId = ReceivableInvoiceDetails.EntityId AND ReceivableInvoiceDetails.EntityType = 'CT'
JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id
WHERE ReceivableInvoiceDetails.IsActive=1
AND ReceivableInvoices.IsActive=1
GROUP BY C.ContractId
SELECT ContractLateFeeInfo.ContractId
,ContractLateFeeInfo.LateFeeType
,CASE WHEN ReceivableInvoices.DueDate = ContractLateFeeInfo.FirstInvoiceDate THEN ContractLateFeeInfo.InvoiceGraceDaysAtInception ELSE ContractLateFeeInfo.InvoiceGraceDays END AS InvoiceGraceDays
,LateFeeAssessments.Id AssessmentId
,LateFeeAssessments.ReceivableInvoiceId
,ReceivableInvoices.DueDate InvoiceDueDate
,ContractLateFeeInfo.ContractType
,Invoice.InvoiceId
INTO #LateFeeAssessmentInfo
FROM @InvoiceInfo Invoice
JOIN LateFeeAssessments ON Invoice.InvoiceId = LateFeeAssessments.ReceivableInvoiceId AND Invoice.ContractId = LateFeeAssessments.ContractId AND LateFeeAssessments.IsActive=1
JOIN (SELECT C.ContractId,CLF.InvoiceGraceDays,CLF.InvoiceGraceDaysAtInception,LFT.LateFeeType,FI.FirstInvoiceDate,Contracts.ContractType
FROM @ContractIds C
JOIN Contracts ON C.ContractId = Contracts.Id
JOIN ContractLateFees CLF ON Contracts.Id = CLF.Id
JOIN LateFeeTemplates LFT ON CLF.LateFeeTemplateId = LFT.Id
JOIN @FirstInvoiceInfo FI ON C.ContractId = FI.ContractId)
AS ContractLateFeeInfo ON LateFeeAssessments.ContractId = ContractLateFeeInfo.ContractId
JOIN ReceivableInvoices ON LateFeeAssessments.ReceivableInvoiceId = ReceivableInvoices.Id
INSERT INTO @LateFeeReceivableReversalInfo
SELECT LateFeeReceivables.Id LateFeeReceivableId,
#LateFeeAssessmentInfo.InvoiceDueDate,
LateFeeReceivables.InstrumentTypeId,
LateFeeReceivables.LineofBusinessId,
LateFeeReceivables.CostCenterId,
#LateFeeAssessmentInfo.AssessmentId,
Receivables.Id ReceivableId,
#LateFeeAssessmentInfo.ContractType,
#LateFeeAssessmentInfo.ContractId,
#LateFeeAssessmentInfo.InvoiceId,
LateFeeReceivables.ReceivableAmendmentType,
0,
CASE WHEN ReceivableDetails.BilledStatus = 'Invoiced' THEN 1 ELSE 0 END AS IsInvoiced
FROM #LateFeeAssessmentInfo
JOIN LateFeeReceivables ON #LateFeeAssessmentInfo.InvoiceId = LateFeeReceivables.ReceivableInvoiceId
AND #LateFeeAssessmentInfo.ContractId = LateFeeReceivables.EntityId AND LateFeeReceivables.EntityType = 'Contract'
AND LateFeeReceivables.IsActive=1 AND LateFeeReceivables.IsManuallyAssessed = 0
JOIN Receivables ON LateFeeReceivables.Id = Receivables.SourceId AND Receivables.SourceTable = 'LateFee' AND Receivables.IsActive=1
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive=1
JOIN (SELECT Invoice.InvoiceId,Invoice.ContractId,ISNULL(MIN(LFR.DueDate),@ProcessThroughDate) FirstLateFeeReceivableDate
FROM @InvoiceInfo Invoice
LEFT JOIN LateFeeReceivables LFR ON Invoice.InvoiceId = LFR.ReceivableInvoiceId AND LFR.EntityId = Invoice.ContractId AND LFR.EntityType = 'Contract' AND LFR.IsActive=1 AND LFR.DueDate > @ProcessThroughDate AND LFR.IsManuallyAssessed = 0
GROUP BY Invoice.InvoiceId,Invoice.ContractId)
AS FirstLateFeeReceivable ON #LateFeeAssessmentInfo.ReceivableInvoiceId = FirstLateFeeReceivable.InvoiceId AND #LateFeeAssessmentInfo.ContractId = FirstLateFeeReceivable.ContractId
WHERE
(#LateFeeAssessmentInfo.LateFeeType <> 'Interest' AND #LateFeeAssessmentInfo.LateFeeType <> 'Other'
AND ((CAST(DATEADD(DAY,#LateFeeAssessmentInfo.InvoiceGraceDays,#LateFeeAssessmentInfo.InvoiceDueDate) AS DATE) < @ProcessThroughDate
AND LateFeeReceivables.DueDate >= CAST(DATEADD(DAY,1,FirstLateFeeReceivable.FirstLateFeeReceivableDate) AS DATE))
OR (CAST(DATEADD(DAY,#LateFeeAssessmentInfo.InvoiceGraceDays,#LateFeeAssessmentInfo.InvoiceDueDate) AS DATE) >= @ProcessThroughDate)))
OR
(#LateFeeAssessmentInfo.LateFeeType = 'Interest' OR #LateFeeAssessmentInfo.LateFeeType = 'Other' AND LateFeeReceivables.DueDate >= @ProcessThroughDate);
IF((SELECT COUNT(*) FROM @LateFeeReceivableReversalInfo) > 0)
BEGIN
DECLARE @AssociatedLateFeeReceivables TABLE(LateFeeReceivableId BIGINT,InvoiceDueDate DATE,InstrumentTypeId BIGINT,LineofBusinessId BIGINT,CostCenterId BIGINT,AssessmentId BIGINT,ReceivableId BIGINT,ContractType NVARCHAR(28),ContractId BIGINT,InvoiceId BIGINT,ReceivableAmendmentType NVARCHAR(40),IsCashPosted BIT, IsInvoiced BIT);
INSERT INTO @AssociatedLateFeeReceivables
SELECT * FROM @LateFeeReceivableReversalInfo
WHILE((SELECT COUNT(LateFeeReceivableId) FROM @AssociatedLateFeeReceivables WHERE IsInvoiced =1 ) > 0)
BEGIN
DELETE FROM @AssociatedLateFeeReceivables
INSERT INTO @AssociatedLateFeeReceivables
SELECT
LateFeeReceivables.Id,
ReceivableInvoices.DueDate,
LateFeeReceivables.InstrumentTypeId,
LateFeeReceivables.LineofBusinessId,
LateFeeReceivables.CostCenterId,
LateFeeAssessments.Id,
Receivables.Id,
LateFeeReceivableReversalInfo.ContractType,
LateFeeReceivableReversalInfo.ContractId,
ReceivableInvoices.Id,
LateFeeReceivables.ReceivableAmendmentType,
0,
CASE WHEN LRD.BilledStatus = 'Invoiced' THEN 1 ELSE 0 END AS IsInvoiced
FROM @AssociatedLateFeeReceivables LateFeeReceivableReversalInfo
JOIN ReceivableDetails ON LateFeeReceivableReversalInfo.ReceivableId = ReceivableDetails.ReceivableId AND ReceivableDetails.BilledStatus = 'Invoiced' AND ReceivableDetails.IsActive=1
JOIN ReceivableInvoiceDetails ON ReceivableDetails.Id = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive=1
JOIN ReceivableInvoices ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId AND ReceivableInvoices.IsActive=1
JOIN LateFeeReceivables ON ReceivableInvoices.Id = LateFeeReceivables.ReceivableInvoiceId AND LateFeeReceivables.EntityType = 'Contract'
AND LateFeeReceivables.EntityId = LateFeeReceivableReversalInfo.ContractId
AND LateFeeReceivables.IsActive=1 AND LateFeeReceivables.IsManuallyAssessed = 0
JOIN LateFeeAssessments ON LateFeeReceivables.EntityId = LateFeeAssessments.ContractId AND LateFeeReceivables.ReceivableInvoiceId = LateFeeAssessments.ReceivableInvoiceId AND LateFeeAssessments.IsActive=1
JOIN Receivables ON LateFeeReceivables.Id = Receivables.SourceId AND Receivables.SourceTable = 'LateFee' AND Receivables.IsActive=1
JOIN ReceivableDetails LRD ON Receivables.Id = LRD.ReceivableId AND LRD.IsActive=1
WHERE LateFeeReceivableReversalInfo.IsInvoiced = 1
INSERT INTO @LateFeeReceivableReversalInfo
SELECT * FROM @AssociatedLateFeeReceivables
END
DECLARE @AdjustmentInfo TABLE(ReceivableId BIGINT, ReceiptNumber NVARCHAR(40) NULL,InvoiceNumber NVARCHAR(80) NULL);
IF(@ValidateForInvoicedReceivables = 1 AND (SELECT COUNT(*) FROM @LateFeeReceivableReversalInfo WHERE IsInvoiced = 1) > 0)
BEGIN
INSERT INTO @AdjustmentInfo(ReceivableId,InvoiceNumber)
SELECT LFR.ReceivableId,ReceivableInvoices.Number
FROM @LateFeeReceivableReversalInfo LFR
JOIN ReceivableDetails ON LFR.ReceivableId = ReceivableDetails.ReceivableId AND LFR.IsInvoiced = 1 AND ReceivableDetails.IsActive=1
JOIN ReceivableInvoiceDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id AND ReceivableInvoiceDetails.IsActive=1
JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive=1
GROUP BY LFR.ReceivableId,ReceivableInvoices.Number
END
IF(@ValidateForCashPostedReceivables = 1)
BEGIN
UPDATE @LateFeeReceivableReversalInfo
SET IsCashPosted = 1
FROM @LateFeeReceivableReversalInfo LFR
JOIN ReceivableTaxes ON LFR.ReceivableId = ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1 AND ReceivableTaxes.Amount_Amount <> ReceivableTaxes.Balance_Amount
WHERE LFR.IsCashPosted = 0
IF ((SELECT COUNT(*) FROM @LateFeeReceivableReversalInfo WHERE IsCashPosted = 1) > 0)
BEGIN
INSERT INTO @AdjustmentInfo(ReceivableId,ReceiptNumber)
SELECT LFR.ReceivableId,Receipts.Number
FROM @LateFeeReceivableReversalInfo LFR
JOIN ReceivableDetails ON LFR.IsCashPosted = 1 AND LFR.ReceivableId = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive=1
JOIN ReceiptApplicationReceivableDetails ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId AND ReceiptApplicationReceivableDetails.IsActive=1
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id AND Receipts.Status IN ('Completed','Posted')
GROUP BY LFR.ReceivableId,Receipts.Number
HAVING SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) <> 0 OR SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) <> 0
END
IF((SELECT COUNT(*) FROM @ReceivableIdsInCurrentReceipt) > 0)
BEGIN
INSERT INTO @AdjustmentInfo(ReceivableId,ReceiptNumber)
SELECT ReceivableId,@ReceiptNumber FROM @ReceivableIdsInCurrentReceipt
END
END
IF((SELECT COUNT(*) FROM @AdjustmentInfo) > 0)
BEGIN
SELECT
LFR.LateFeeReceivableId,
LFR.InvoiceDueDate,
LFR.InstrumentTypeId,
LFR.LineofBusinessId,
LFR.CostCenterId,
LFR.AssessmentId,
LFR.ReceivableId,
LFR.ContractType,
LFR.ContractId,
LFR.InvoiceId,
LFR.ReceivableAmendmentType,
CASE WHEN InvoicedReceivables.ReceivableId IS NULL THEN NULL
ELSE STUFF((SELECT ', ' + InvoiceNumber FROM @AdjustmentInfo AdjustmentInfo
WHERE AdjustmentInfo.ReceivableId = LFR.ReceivableId AND AdjustmentInfo.InvoiceNumber IS NOT NULL
FOR XML PATH('')), 1, 2, '')
END AS InvoiceNumbers,
CASE WHEN CashPostedReceivables.ReceivableId IS NULL THEN NULL
ELSE STUFF((SELECT ', ' + ReceiptNumber FROM @AdjustmentInfo AdjustmentInfo
WHERE AdjustmentInfo.ReceivableId = LFR.ReceivableId AND AdjustmentInfo.ReceiptNumber IS NOT NULL
FOR XML PATH('')), 1, 2, '')
END AS ReceiptNumbers
FROM @LateFeeReceivableReversalInfo LFR
LEFT JOIN (SELECT AdjustmentInfo.ReceivableId FROM @AdjustmentInfo AdjustmentInfo WHERE AdjustmentInfo.InvoiceNumber IS NOT NULL GROUP BY AdjustmentInfo.ReceivableId) AS InvoicedReceivables ON LFR.ReceivableId = InvoicedReceivables.ReceivableId
LEFT JOIN (SELECT AdjustmentInfo.ReceivableId FROM @AdjustmentInfo AdjustmentInfo WHERE AdjustmentInfo.ReceiptNumber IS NOT NULL GROUP BY AdjustmentInfo.ReceivableId) AS CashPostedReceivables ON LFR.ReceivableId = CashPostedReceivables.ReceivableId
END
ELSE
BEGIN
If (@CanUpdate = 1)
BEGIN
UPDATE LateFeeReceivables
SET IsActive = 0, ReversedDate = @ReversedDate,UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM LateFeeReceivables
JOIN @LateFeeReceivableReversalInfo LFR ON LateFeeReceivables.Id = LFR.LateFeeReceivableId
JOIN #LateFeeAssessmentInfo ON LateFeeReceivables.ReceivableInvoiceId = #LateFeeAssessmentInfo.ReceivableInvoiceId
WHERE (LateFeeReceivables.StartDate > @ProcessThroughDate
OR DATEADD(DD,#LateFeeAssessmentInfo.InvoiceGraceDays, #LateFeeAssessmentInfo.InvoiceDueDate) >= @ProcessThroughDate);
UPDATE LateFeeAssessments
SET LateFeeAssessedUntilDate = AssessmentInfo.AssessedTillDate,
FullyAssessed = 0,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM LateFeeAssessments
JOIN (SELECT Assessments.AssessmentId,ISNULL(MAX(LateFeeReceivables.EndDate),Assessments.InvoiceDueDate) AS AssessedTillDate
FROM (SELECT InvoiceId,AssessmentId,ContractId,InvoiceDueDate FROM @LateFeeReceivableReversalInfo GROUP BY InvoiceId,AssessmentId,ContractId,InvoiceDueDate) AS Assessments
LEFT JOIN LateFeeReceivables ON Assessments.InvoiceId = LateFeeReceivables.ReceivableInvoiceId AND Assessments.ContractId = LateFeeReceivables.EntityId
AND LateFeeReceivables.EntityType = 'Contract' AND LateFeeReceivables.IsActive=1 AND LateFeeReceivables.IsManuallyAssessed = 0
GROUP BY Assessments.AssessmentId,Assessments.InvoiceDueDate) AS AssessmentInfo
ON LateFeeAssessments.Id = AssessmentInfo.AssessmentId;
END
SELECT
LFRI.LateFeeReceivableId,
LFRI.InvoiceDueDate,
LFRI.InstrumentTypeId,
LFRI.LineofBusinessId,
LFRI.CostCenterId,
LFRI.AssessmentId,
LFRI.ReceivableId,
LFRI.ContractType,
LFRI.ContractId,
LFRI.InvoiceId,
LFRI.ReceivableAmendmentType,
NULL AS InvoiceNumbers,
NULL AS ReceiptNumbers
FROM
@LateFeeReceivableReversalInfo LFRI
JOIN LateFeeReceivables ON LFRI.LateFeeReceivableId = LateFeeReceivables.Id
WHERE IsActive = 0
END
END
DROP TABLE #LateFeeAssessmentInfo
END

GO
