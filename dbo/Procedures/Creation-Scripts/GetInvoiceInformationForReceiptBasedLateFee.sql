SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetInvoiceInformationForReceiptBasedLateFee]
(
@ReceiptId BIGINT,
@PaymentDate DATE,
@IsDSLReceipt BIT
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #ReceiptDetails
(
ContractId BIGINT,
ReceivableInvoiceId BIGINT,
ReceivableTypeId BIGINT,
AmountApplied DECIMAL(16,2),
TaxApplied DECIMAL(16,2),
ExchangeRate DECIMAL(20,10),
AlternateBillingCurrencyId BIGINT
);
CREATE TABLE #ReceivableInvoiceInfo
(
ReceivableInvoiceId BIGINT NOT NULL,
ContractLateFeeTemplateId BIGINT NULL,
CustomerId BIGINT NOT NULL,
ContractId BIGINT NOT NULL,
InvoiceDate DATE,
SequenceNumber NVARCHAR(40),
ContractType NVARCHAR(14),
InvoiceNumber NVARCHAR(40),
InvoiceGraceDays INT,
ReceivableTypeId BIGINT NOT NULL,
AmountApplied DECIMAL(16,2),
TaxApplied DECIMAL(16,2),
WaiveIfLateFeeBelowAmount DECIMAL(16,2),
ConversionSource NVARCHAR(50) NULL,
AlternateBillingCurrencyId BIGINT,
ExchangeRate DECIMAL(18,8),
ReceivableDueDate DATE,
CurrencyCode NVARCHAR(10)
);
IF(@IsDSLReceipt = 1)
BEGIN
INSERT INTO #ReceiptDetails
SELECT
Receivables.EntityId ContractId,
DSLReceiptHistories.InvoiceId ReceivableInvoiceId,
ReceivableCodes.ReceivableTypeId ReceivableTypeId,
SUM(DSLReceiptHistories.AmountPosted_Amount) AS AmountApplied,
0 AS TaxApplied,
Receivables.ExchangeRate,
Receivables.AlternateBillingCurrencyId
FROM DSLReceiptHistories
JOIN ReceivableDetails ON DSLReceiptHistories.ReceivableDetailId = ReceivableDetails.Id
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN LegalEntities ON Receivables.LegalEntityId = LegalEntities.Id
WHERE DSLReceiptHistories.ReceiptId = @ReceiptId
AND LegalEntities.LateFeeApproach = 'ReceiptBased'
AND DSLReceiptHistories.InvoiceId IS NOT NULL
AND Receivables.EntityType = 'CT'
AND DSLReceiptHistories.IsActive=1
AND DSLReceiptHistories.AmountPosted_Amount  <> 0
GROUP BY DSLReceiptHistories.InvoiceId,Receivables.EntityId,ReceivableCodes.ReceivableTypeId,Receivables.ExchangeRate,Receivables.AlternateBillingCurrencyId
END
ELSE
BEGIN
INSERT INTO #ReceiptDetails
SELECT
Receivables.EntityId ContractId,
ReceiptApplicationReceivableDetails.ReceivableInvoiceId,
ReceivableCodes.ReceivableTypeId,
SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) AS AmountApplied,
SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) AS TaxApplied,
Receivables.ExchangeRate,
Receivables.AlternateBillingCurrencyId
FROM ReceiptApplications
JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId AND ReceiptApplicationReceivableDetails.IsActive=1
JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN LegalEntities ON Receivables.LegalEntityId = LegalEntities.Id
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND LegalEntities.LateFeeApproach = 'ReceiptBased'
AND ReceiptApplicationReceivableDetails.ReceivableInvoiceId IS NOT NULL
AND Receivables.EntityType = 'CT'
AND (ReceiptApplicationReceivableDetails.AmountApplied_Amount <> 0 OR ReceiptApplicationReceivableDetails.TaxApplied_Amount <> 0)
GROUP BY Receivables.EntityId,ReceiptApplicationReceivableDetails.ReceivableInvoiceId,ReceivableCodes.ReceivableTypeId,Receivables.ExchangeRate,Receivables.AlternateBillingCurrencyId
END
SELECT DISTINCT #ReceiptDetails.* INTO #InvoiceSummary
FROM #ReceiptDetails
LEFT JOIN LateFeeReceivables ON @ReceiptId = LateFeeReceivables.ReceiptId
AND #ReceiptDetails.ReceivableInvoiceId = LateFeeReceivables.ReceivableInvoiceId
AND #ReceiptDetails.ContractId = LateFeeReceivables.EntityId
AND LateFeeReceivables.IsActive=1
WHERE LateFeeReceivables.ReceiptId IS NULL
IF EXISTS(SELECT ReceivableInvoiceId FROM #InvoiceSummary)
BEGIN
SELECT ReceivableInvoiceDetails.EntityId ContractId,MIN(ReceivableInvoices.DueDate) FirstInvoiceDate
INTO #FirstInvoiceInfo
FROM ReceivableInvoiceDetails
JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id
JOIN (SELECT DISTINCT ContractId FROM #InvoiceSummary) AS ContractInfo ON ReceivableInvoiceDetails.EntityId = ContractInfo.ContractId
WHERE ReceivableInvoiceDetails.EntityType = 'CT'
AND ReceivableInvoiceDetails.IsActive=1
AND ReceivableInvoices.IsActive=1
GROUP BY ReceivableInvoiceDetails.EntityId
;WITH CTE_ReceivableDueDate AS
(
SELECT
MAX(R.DueDate) ReceivableDueDate
,RI.ReceivableInvoiceId ReceivableInvoiceId
FROM #InvoiceSummary RI
JOIN ReceivableInvoiceDetails RID on RID.ReceivableInvoiceId = RI.ReceivableInvoiceId
JOIN ReceivableDetails RD on RID.ReceivableDetailId = RD.Id
JOIN Receivables R on RD.Receivableid = R.Id
GROUP BY RI.ReceivableInvoiceId
)
INSERT INTO #ReceivableInvoiceInfo
SELECT
DISTINCT
#InvoiceSummary.ReceivableInvoiceId AS ReceivableInvoiceId,
ContractLateFees.LateFeeTemplateId ContractLateFeeTemplateId,
Customers.Id CustomerId,
#InvoiceSummary.ContractId ContractId,
ReceivableInvoices.DueDate InvoiceDate,
Contracts.SequenceNumber SequenceNumber,
Contracts.ContractType,
ReceivableInvoices.Number InvoiceNumber,
CASE WHEN ReceivableInvoices.DueDate = #FirstInvoiceInfo.FirstInvoiceDate AND ContractLateFees.InvoiceGraceDaysAtInception <> 0
THEN ContractLateFees.InvoiceGraceDaysAtInception
ELSE ContractLateFees.InvoiceGraceDays
END AS InvoiceGraceDays,
#InvoiceSummary.ReceivableTypeId,
#InvoiceSummary.AmountApplied,
#InvoiceSummary.TaxApplied,
ContractLateFees.WaiveIfLateFeeBelow_Amount WaiveIfLateFeeBelowAmount,
Contracts.u_ConversionSource ConversionSource,
#InvoiceSummary.AlternateBillingCurrencyId,
#InvoiceSummary.ExchangeRate,
CTE_ReceivableDueDate.ReceivableDueDate,
ReceivableInvoices.InvoiceAmount_Currency
FROM #InvoiceSummary
JOIN ReceivableInvoices ON #InvoiceSummary.ReceivableInvoiceId = ReceivableInvoices.Id
JOIN Contracts ON #InvoiceSummary.ContractId = Contracts.Id
JOIN #FirstInvoiceInfo ON Contracts.Id = #FirstInvoiceInfo.ContractId
JOIN CTE_ReceivableDueDate ON CTE_ReceivableDueDate.ReceivableInvoiceId = ReceivableInvoices.Id
JOIN ContractLateFees ON #InvoiceSummary.ContractId = ContractLateFees.Id
JOIN Customers ON ReceivableInvoices.CustomerId = Customers.Id
JOIN ContractLateFeeReceivableTypes ON ContractLateFees.Id = ContractLateFeeReceivableTypes.ContractLateFeeId AND #InvoiceSummary.ReceivableTypeId = ContractLateFeeReceivableTypes.ReceivableTypeId AND ContractLateFeeReceivableTypes.IsActive=1
WHERE Contracts.Status <> 'Terminated'
AND ContractLateFees.LateFeeTemplateId IS NOT NULL
AND ReceivableInvoices.IsActive=1
AND (ContractLateFees.WaiveIfInvoiceAmountBelow_Amount = 0 OR ABS(ReceivableInvoices.InvoiceAmount_Amount) >= ContractLateFees.WaiveIfInvoiceAmountBelow_Amount)
AND ((ReceivableInvoices.DueDate = #FirstInvoiceInfo.FirstInvoiceDate AND DATEADD(DAY,ContractLateFees.InvoiceGraceDaysAtInception,ReceivableInvoices.DueDate) < @PaymentDate)
OR ((ReceivableInvoices.DueDate <> #FirstInvoiceInfo.FirstInvoiceDate OR ContractLateFees.InvoiceGraceDaysAtInception = 0) AND DATEADD(DAY,ContractLateFees.InvoiceGraceDays,ReceivableInvoices.DueDate) < @PaymentDate))
END
SELECT
@ReceiptId AS ReceiptId,
ReceivableInvoiceId,
ContractLateFeeTemplateId,
CustomerId,
ContractId,
InvoiceDate,
SequenceNumber,
ContractType,
InvoiceNumber,
InvoiceGraceDays,
SUM(AmountApplied) AmountApplied,
SUM(TaxApplied) TaxApplied,
WaiveIfLateFeeBelowAmount,
ConversionSource,
ExchangeRate,
CurrencyCode,
AlternateBillingCurrencyId,
ReceivableDueDate,
@PaymentDate AS PaymentDate,
CONVERT(BIT, 0) HasError,
CONVERT(BIT, 0) ContractLevelTemplateDoesNotExists
FROM
#ReceivableInvoiceInfo
GROUP BY
ReceivableInvoiceId,
ContractLateFeeTemplateId,
CustomerId,
ContractId,
InvoiceDate,
SequenceNumber,
ContractType,
InvoiceNumber,
InvoiceGraceDays,
WaiveIfLateFeeBelowAmount,
ConversionSource,
ExchangeRate,
CurrencyCode,
AlternateBillingCurrencyId,
ReceivableDueDate
DROP TABLE #FirstInvoiceInfo
DROP TABLE #ReceivableInvoiceInfo
DROP TABLE #InvoiceSummary
DROP TABLE #ReceiptDetails
SET NOCOUNT OFF;
END

GO
