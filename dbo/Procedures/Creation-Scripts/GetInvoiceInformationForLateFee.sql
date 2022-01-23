SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetInvoiceInformationForLateFee]
(
@SelectedLegalEntityIds SelectedLegalEntityIds READONLY,
@CustomerIds CustomerIds READONLY,
@ProcessThroughDate DATE,
@SystemDate DATE,
@EntityType NVARCHAR(2),
@ContractType NVARCHAR(14) = NULL,
@ContractId BIGINT = NULL
)
AS
BEGIN
SET NOCOUNT ON
SELECT LegalEntities.Id INTO #SelectedLegalEntityIds
FROM @SelectedLegalEntityIds S
JOIN LegalEntities ON S.LegalEntityId = LegalEntities.Id
WHERE LegalEntities.LateFeeApproach <> 'ReceiptBased'

SELECT * INTO #Customers FROM @CustomerIds

CREATE TABLE #InvoiceInfo (InvoiceId BIGINT,ContractId BIGINT,InvoiceDueDate DATE,IsFirstInvoice TINYINT, InvoiceGraceDays INT ,LateFeeAssessedTillDate DATE
,IsEligible TINYINT, WaiveIfInvoiceAmountBelowAmount DECIMAL(18,2),ExchangeRate DECIMAL(30,10));

INSERT INTO #InvoiceInfo
SELECT 
 ReceivableInvoices.Id AS ReceivableInvoiceId
,Contracts.Id ContractId
,ReceivableInvoices.DueDate
,0
,ContractLateFees.InvoiceGraceDays
,LateFeeAssessments.LateFeeAssessedUntilDate
,1 
,ContractLateFees.WaiveIfInvoiceAmountBelow_Amount WaiveIfInvoiceAmountBelowAmount
,ReceivableInvoiceDetails.ExchangeRate
FROM ReceivableInvoices
INNER JOIN #Customers ON ReceivableInvoices.CustomerId = #Customers.CustomerId
	AND ReceivableInvoices.DueDate <= @SystemDate AND ReceivableInvoices.DueDate <= @ProcessThroughDate
	AND ReceivableInvoices.IsActive=1
	AND ReceivableInvoices.IsDummy = 0
INNER JOIN #SelectedLegalEntityIds on ReceivableInvoices.LegalEntityId = #SelectedLegalEntityIds.Id
INNER JOIN ReceivableInvoiceDetails ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId 
	AND ReceivableInvoiceDetails.EntityType = @EntityType
	AND ReceivableInvoiceDetails.IsActive=1
INNER JOIN Contracts ON  Contracts.Id = ReceivableInvoiceDetails.EntityId
INNER JOIN ContractLateFees ON Contracts.Id = ContractLateFees.Id AND ContractLateFees.LateFeeTemplateId IS NOT NULL
LEFT JOIN LateFeeAssessments ON ReceivableInvoices.Id = LateFeeAssessments.ReceivableInvoiceId and Contracts.Id = LateFeeAssessments.ContractId
WHERE (@ContractId IS NULL OR Contracts.Id = @ContractId) 
AND Contracts.Status <> 'Terminated'
AND (ReceivableInvoices.Balance_Amount > 0 
	OR ReceivableInvoices.TaxBalance_Amount > 0 
	OR ReceivableInvoices.LastReceivedDate IS NULL 
	OR ReceivableInvoices.LastReceivedDate > ReceivableInvoices.DueDate)
AND (LateFeeAssessments.ReceivableInvoiceId IS NULL 
	OR (LateFeeAssessments.FullyAssessed = 0 AND LateFeeAssessments.LateFeeAssessedUntilDate < @ProcessThroughDate))
GROUP BY ReceivableInvoices.Id , Contracts.Id, ReceivableInvoices.DueDate, ContractLateFees.InvoiceGraceDays, 
LateFeeAssessments.LateFeeAssessedUntilDate, Contracts.u_ConversionSource,ContractLateFees.WaiveIfInvoiceAmountBelow_Amount,ReceivableInvoiceDetails.ExchangeRate

;WITH Contract_CTE AS 
(SELECT #InvoiceInfo.ContractId,MIN(ReceivableInvoices.DueDate) FirstInvoiceDueDate
FROM #InvoiceInfo
INNER JOIN ReceivableInvoiceDetails ON #InvoiceInfo.ContractId = ReceivableInvoiceDetails.EntityId
AND ReceivableInvoiceDetails.EntityType = @EntityType 
INNER JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive=1
where ReceivableInvoiceDetails.IsActive=1
GROUP BY #InvoiceInfo.ContractId)

Update I set IsFirstInvoice = 1
from #InvoiceInfo I
inner join Contract_CTE C on I.contractId = C.ContractId
where I.InvoiceDueDate = C.FirstInvoiceDueDate

Update I set InvoiceGraceDays = C.InvoiceGraceDaysAtInception
from #InvoiceInfo I
inner join ContractLateFees C on I.contractId = C.Id
where I.IsFirstInvoice = 1 and C.InvoiceGraceDaysAtInception <> 0

Update I set IsEligible = 0
from #InvoiceInfo I
INNER JOIN ReceivableInvoices ON I.InvoiceId = ReceivableInvoices.Id
WHERE (ReceivableInvoices.InvoiceAmount_Amount + ReceivableInvoices.InvoiceTaxAmount_Amount) < I.WaiveIfInvoiceAmountBelowAmount

Update #InvoiceInfo set IsEligible = 0 Where DATEADD(DAY,InvoiceGraceDays,InvoiceDueDate ) > @SystemDate AND IsEligible <> 0

SELECT
I.InvoiceId,
I.ContractId,
ReceivableInvoiceDetails.ReceivableDetailId 
INTO #InvoicewithReceivablesToBeProcessed
FROM #InvoiceInfo I
JOIN ReceivableInvoiceDetails ON I.InvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId AND ReceivableInvoiceDetails.EntityId = I.ContractId AND ReceivableInvoiceDetails.EntityType = @EntityType
AND ReceivableInvoiceDetails.IsActive=1
JOIN Receivables ON ReceivableInvoiceDetails.ReceivableId = Receivables.Id AND Receivables.IsActive=1 AND Receivables.IsCollected=1
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ContractLateFeeReceivableTypes ON I.ContractId = ContractLateFeeReceivableTypes.ContractLateFeeId AND ReceivableCodes.ReceivableTypeId = ContractLateFeeReceivableTypes.ReceivableTypeId AND ContractLateFeeReceivableTypes.IsActive=1
WHERE
I.IsEligible = 1;

SELECT
I.InvoiceId,
I.ContractId,
SUM(ReceivableInvoiceDetails.InvoiceAmount_Amount) Amount,
SUM(ReceivableInvoiceDetails.InvoiceTaxAmount_Amount) TaxAmount,
SUM(ReceivableInvoiceDetails.Balance_Amount) Balance,
SUM(ReceivableInvoiceDetails.TaxBalance_Amount) TaxBalance,
SUM(ReceivableInvoiceDetails.ReceivableAmount_Amount) ReceivableAmount,
Max(Receivables.DueDate) ReceivableDueDate
INTO #InvoiceAmountSummary
FROM #InvoicewithReceivablesToBeProcessed I
JOIN ReceivableInvoiceDetails ON I.InvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId AND I.ReceivableDetailId =ReceivableInvoiceDetails.ReceivableDetailId
INNER JOIN Receivables ON ReceivableInvoiceDetails.ReceivableId = Receivables.Id
Group By I.InvoiceId, I.ContractId

SELECT
I.InvoiceId,
I.ContractId
,SUM(ReceivableTaxDetails.Amount_Amount) AS ReceivableTaxAmount
INTO #TaxAmount
FROM #InvoicewithReceivablesToBeProcessed I
JOIN ReceivableTaxDetails ON I.ReceivableDetailId = ReceivableTaxDetails.ReceivableDetailId AND ReceivableTaxDetails.IsActive = 1
JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id AND ReceivableTaxes.IsActive = 1
Group By I.InvoiceId, I.ContractId

SELECT
 I.InvoiceId
,I.ContractId
,I.InvoiceDueDate
,I.InvoiceGraceDays
,ReceivableInvoices.Number InvoiceNumber
,I.LateFeeAssessedTillDate
,ContractLateFees.LateFeeTemplateId ContractLateFeeTemplateId
,ContractLateFees.WaiveIfLateFeeBelow_Amount WaiveIfLateFeeBelowAmount
,ReceivableInvoices.CustomerId 
,ReceivableInvoices.InvoiceAmount_Currency CurrencyCode
,ReceivableInvoices.AlternateBillingCurrencyId
,Contracts.SequenceNumber,
IA.ReceivableDueDate,
I.ExchangeRate
,IA.Amount
,IA.TaxAmount
,IA.Balance
,IA.TaxBalance
,IA.ReceivableAmount
,ISNULL(TA.ReceivableTaxAmount, 0.00) AS ReceivableTaxAmount
FROM
#InvoiceInfo I
INNER JOIN #InvoiceAmountSummary IA on I.InvoiceId = IA.InvoiceId AND I.ContractId = IA.ContractId
INNER JOIN ReceivableInvoices ON I.InvoiceId = ReceivableInvoices.Id
INNER JOIN Contracts ON I.ContractId = Contracts.Id
INNER JOIN ContractLateFees ON I.ContractId = ContractLateFees.Id
LEFT JOIN #TaxAmount TA on I.InvoiceId = TA.InvoiceId AND I.ContractId = TA.ContractId;

CREATE TABLE #Receipts (InvoiceId BIGINT,ContractId BIGINT, AmountPaid DECIMAL(18,2), TaxPaid DECIMAL(18,2), ReceivedDate DATE)

INSERT INTO #Receipts
Select
I.InvoiceId,
I.ContractId,
SUM(rard.AmountApplied_Amount) AmountPaid,
SUM(rard.TaxApplied_Amount) TaxPaid,
Case WHEN r.ReceiptClassification = 'NonAccrualNonDSLNonCash' OR r.ReceiptClassification = 'NonCash' THEN r.PostDate ELSE r.ReceivedDate END [ReceivedDate]
From #InvoicewithReceivablesToBeProcessed I
join ReceiptApplicationReceivableDetails rard on rard.ReceivableDetailId = I.ReceivableDetailId and rard.IsActive = 1
Join ReceiptApplications ra On rard.ReceiptApplicationId = ra.Id
Join Receipts r On ra.ReceiptId = r.Id
where (r.Status = 'Posted' OR r.Status = 'Completed') And r.ReceiptClassification <> 'DSL'
GROUP BY I.InvoiceId, I.ContractId, r.PostDate, r.ReceivedDate, r.ReceiptClassification;

INSERT INTO #Receipts
Select
I.InvoiceId ,
I.ContractId,
SUM(dr.AmountPosted_Amount) AmountPaid,
0.0 TaxPaid,
r.ReceivedDate
From 
#InvoicewithReceivablesToBeProcessed I
join DSLReceiptHistories dr on dr.ReceivableDetailId = I.ReceivableDetailId and dr.IsActive = 1
join ReceivableDetails rd on dr.ReceivableDetailId = rd.Id
Join Receipts r On dr.ReceiptId = r.Id
join Receivables rs on rd.ReceivableId = rs.Id
Where r.Status = 'Posted' And rs.IsDSL = 1 And rs.IsDummy = 1
GROUP BY I.InvoiceId ,I.ContractId,r.ReceivedDate

Select InvoiceId ReceivableInvoiceId ,ContractId, SUM(AmountPaid) AmountPaid, SUM(TaxPaid) TaxPaid, ReceivedDate From #Receipts Group By InvoiceId,ContractId, ReceivedDate;

DROP TABLE #SelectedLegalEntityIds
DROP TABLE #InvoiceInfo
DROP TABLE #InvoicewithReceivablesToBeProcessed
DROP TABLE #InvoiceAmountSummary
DROP TABLE #TaxAmount
DROP TABLE #Receipts
DROP TABLE #Customers
END

GO
