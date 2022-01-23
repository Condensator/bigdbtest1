SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ProcessSalesTaxReceivablesForGLTransfer]
(
@EffectiveDate DATE,
@MovePLBalance BIT,
@PLEffectiveDate DATE = NULL,
@ContractInfo ContractIdCollection READONLY,
@ExcludeSalesTaxPayableDuringGLTransfer BIT
)
AS
BEGIN
CREATE TABLE #SalesTaxGLSummary
(
ContractId BIGINT,
GLTransactionType NVARCHAR(56),
GLTemplateId BIGINT,
GLEntryItem NVARCHAR(100),
Amount DECIMAL(16,2),
IsDebit BIT,
MatchingGLTemplateId BIGINT,
MatchingFilter NVARCHAR(80),
InstrumentTypeId BIGINT,
LineofBusinesssId BIGINT,
CostCenterId BIGINT,
LegalEntityId BIGINT
)
CREATE TABLE #SalesTaxReceivableInfo
(
ReceivableId BIGINT,
FunderId BIGINT,
ReceivableCode NVARCHAR(200),
IsGLPosted BIT,
ReceivableTaxId BIGINT,
AccountingTreatment NVARCHAR(24),
EntityType NVARCHAR(6),
ContractId BIGINT,
ContractType NVARCHAR(28),
SequenceNumber NVARCHAR(80),
DueDate DATE,
ReceivableType NVARCHAR(42),
LegalEntityId BIGINT,
CustomerId BIGINT,
CustomerNumber NVARCHAR(80),
TotalAmount DECIMAL(16,2),
TotalBalance DECIMAL(16,2),
Currency NVARCHAR(6),
TaxRemittancePreference NVARCHAR(24),
IsSyndicated BIT,
GLTemplateId BIGINT,
LeaseInstrumentTypeId BIGINT,
LoanInstrumentTypeId BIGINT,
LeaseCostCenterId BIGINT,
LoanCostCenterId BIGINT,
LeveragedLeaseCostCenterId BIGINT,
ReceivableForTransferType NVARCHAR(32),
ReceivableForTransferId BIGINT,
SourceTable NVARCHAR(40),
SourceId BIGINT,
IsIntercompany BIT
);
INSERT INTO #SalesTaxReceivableInfo
SELECT
Receivables.Id AS ReceivableId,
Receivables.FunderId,
ReceivableCodes.Name ReceivableCode,
ReceivableTaxes.IsGLPosted,
ReceivableTaxes.ReceivableTaxId,
ReceivableCodes.AccountingTreatment,
Receivables.EntityType,
ReceivableTaxes.ContractId,
Contracts.ContractType,
Contracts.SequenceNumber,
Receivables.DueDate,
ReceivableTypes.Name ReceivableType,
Receivables.LegalEntityId,
Receivables.CustomerId,
Parties.PartyNumber CustomerNumber,
ReceivableTaxes.Amount TotalAmount,
ReceivableTaxes.Balance TotalBalance,
ReceivableTaxes.CurrencyCode Currency,
CASE WHEN Contracts.ChargeOffStatus <> '_' OR (ReceivableForTransfers.EffectiveDate IS NOT NULL AND Receivables.DueDate >= ReceivableForTransfers.EffectiveDate)
THEN Contracts.SalesTaxRemittanceMethod ELSE LegalEntities.TaxRemittancePreference END TaxRemittancePreference,
CASE WHEN Contracts.SyndicationType NOT IN('_','None') AND ReceivableForTransfers.EffectiveDate IS NOT NULL AND Receivables.DueDate >= ReceivableForTransfers.EffectiveDate AND Receivables.FunderId IS NOT NULL
THEN 1 ELSE 0 END IsSyndicated,
ReceivableTaxes.GLTemplateId,
LeaseFinances.InstrumentTypeId LeaseInstrumentTypeId,
LoanFinances.InstrumentTypeId LoanInstrumentTypeId,
Contracts.CostCenterId LeaseCostCenterId,
Contracts.CostCenterId LoanCostCenterId,
Contracts.CostCenterId LeveragedLeaseCostCenterId,
ISNULL(ReceivableForTransfers.ReceivableForTransferType,'_') ReceivableForTransferType,
ReceivableForTransfers.Id ReceivableForTransferId,
ISNULL(Receivables.SourceTable,'_') SourceTable,
Receivables.SourceId,
Parties.IsIntercompany
FROM (SELECT DISTINCT
Receivables.Id ReceivableId,
C.ContractId,
ReceivableTaxes.Id ReceivableTaxId,
ReceivableTaxDetails.IsGLPosted,
ReceivableTaxes.GLTemplateId,
Receivables.TotalAmount_Currency CurrencyCode,
ReceivableTaxes.Amount_Amount Amount,
CASE WHEN ISNULL(SUM(PrepaidReceivables.PrePaidTaxAmount_Amount),0) <> 0
THEN ReceivableTaxes.Amount_Amount - ISNULL(SUM(PrepaidReceivables.PrePaidTaxAmount_Amount),0)
ELSE ReceivableTaxes.Balance_Amount
END AS Balance
FROM @ContractInfo C
JOIN Receivables ON C.ContractId = Receivables.EntityId AND Receivables.EntityType = 'CT' AND Receivables.IsActive=1
JOIN ReceivableTaxes ON Receivables.Id = ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1
JOIN ReceivableTaxDetails ON ReceivableTaxes.Id = ReceivableTaxDetails.ReceivableTaxId AND ReceivableTaxDetails.IsActive=1
AND (ReceivableTaxDetails.IsGLPosted=1 OR ReceivableTaxDetails.Amount_Amount <> ReceivableTaxDetails.Balance_Amount)
LEFT JOIN PrepaidReceivables ON Receivables.Id = PrepaidReceivables.ReceivableId
WHERE (PrepaidReceivables.ReceivableId IS NULL OR PrepaidReceivables.IsActive=1)
GROUP BY C.ContractId,Receivables.Id,ReceivableTaxes.Id,ReceivableTaxes.GLTemplateId,ReceivableTaxes.Amount_Amount,ReceivableTaxes.Balance_Amount,
Receivables.TotalAmount_Currency,ReceivableTaxDetails.IsGLPosted,ReceivableTaxDetails.Id) AS ReceivableTaxes
JOIN Receivables ON ReceivableTaxes.ReceivableId = Receivables.Id
JOIN Parties ON Receivables.CustomerId = Parties.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN LegalEntities ON Receivables.LegalEntityId = LegalEntities.Id
JOIN Contracts ON ReceivableTaxes.ContractId = Contracts.Id
LEFT JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
LEFT JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
LEFT JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent=1
LEFT JOIN (SELECT C.ContractId,ReceivableForTransfers.Id,ReceivableForTransfers.ReceivableForTransferType,CASE WHEN Contracts.ContractType = 'Lease' THEN LeasePaymentSchedules.StartDate ELSE LoanPaymentSchedules.StartDate END AS EffectiveDate
FROM @ContractInfo C
JOIN Contracts ON C.ContractId = Contracts.Id
JOIN ReceivableForTransfers ON C.ContractId = ReceivableForTransfers.ContractId
LEFT JOIN LeasePaymentSchedules ON ReceivableForTransfers.LeasePaymentId = LeasePaymentSchedules.Id AND Contracts.ContractType = 'Lease'
LEFT JOIN LoanPaymentSchedules ON ReceivableForTransfers.LoanPaymentId = LoanPaymentSchedules.Id AND Contracts.ContractType = 'Loan'
WHERE ReceivableForTransfers.ApprovalStatus = 'Approved' AND
(LeasePaymentSchedules.Id IS NOT NULL OR LoanPaymentSchedules.Id IS NOT NULL)) AS ReceivableForTransfers ON Contracts.Id = ReceivableForTransfers.ContractId
LEFT JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id AND Contracts.ContractType = 'Lease' AND Receivables.SourceTable <> 'CPUSchedule'
LEFT JOIN LoanPaymentSchedules ON Receivables.PaymentScheduleId = LoanPaymentSchedules.Id AND Contracts.ContractType IN('Loan','ProgressLoan')
WHERE ISNULL(ISNULL(LeasePaymentSchedules.EndDate,LoanPaymentSchedules.EndDate),Receivables.DueDate) < @EffectiveDate
IF EXISTS(SELECT ContractId FROM #SalesTaxReceivableInfo)
BEGIN
CREATE TABLE #SalesTaxEntryItemBalances (ContractId BIGINT,GLTemplateId BIGINT,IsSyndicated BIT,SalesTaxReceivableBalance DECIMAL(16,2),PrePaidSalesTaxReceivableBalance DECIMAL(16,2),SalesTaxPayableBalance DECIMAL(16,2),UncollectedSalesTaxARBalance DECIMAL(16,2));
INSERT INTO #SalesTaxEntryItemBalances
SELECT ContractId,
GLTemplateId,
IsSyndicated,
SUM(SalesTaxReceivableBalance),
SUM(PrePaidSalesTaxReceivableBalance),
CASE WHEN @ExcludeSalesTaxPayableDuringGLTransfer = 1 THEN 0 ELSE SUM(SalesTaxPayableBalance) END,
SUM(UncollectedSalesTaxARBalance)
FROM
(SELECT SalesTaxReceivable.ContractId,
SalesTaxReceivable.GLTemplateId,
SalesTaxReceivable.IsSyndicated,
CASE WHEN IsGLPosted=1 THEN TotalBalance ELSE 0 END AS SalesTaxReceivableBalance,
CASE WHEN IsGLPosted=0 THEN TotalBalance - TotalAmount ELSE 0 END AS PrePaidSalesTaxReceivableBalance,
CASE WHEN TaxRemittancePreference = 'AccrualBased'
THEN CASE WHEN IsGLPosted = 1 THEN TotalAmount - ISNULL(PayableInfo.TotalClearedTaxPortion,0) ELSE 0 - ISNULL(PayableInfo.TotalClearedTaxPortion,0) END
ELSE (TotalAmount - TotalBalance) - ISNULL(PayableInfo.TotalClearedTaxPortion,0)
END AS SalesTaxPayableBalance,
CASE WHEN TaxRemittancePreference = 'AccrualBased'
THEN 0 ELSE CASE WHEN IsGLPosted = 1 THEN TotalBalance ELSE TotalBalance - TotalAmount END
END AS UncollectedSalesTaxARBalance
FROM #SalesTaxReceivableInfo SalesTaxReceivable
LEFT JOIN (SELECT Payables.SourceId ReceivableId,SUM(Payables.Amount_Amount - Payables.TaxPortion_Amount) TotalClearedReceivablePortion,SUM(Payables.TaxPortion_Amount) TotalClearedTaxPortion
FROM
(SELECT ReceivableId FROM #SalesTaxReceivableInfo WHERE IsSyndicated=1 AND FunderId IS NOT NULL GROUP BY ReceivableId) AS SyndicatedReceivables
JOIN Payables ON SyndicatedReceivables.ReceivableId = Payables.SourceId AND Payables.SourceTable = 'SyndicatedAR' AND Payables.Status <> 'Inactive' AND Payables.IsGLPosted=1
JOIN Sundries ON Payables.Id = Sundries.PayableId AND Sundries.IsActive=1
GROUP BY Payables.SourceId)
AS PayableInfo ON SalesTaxReceivable.ReceivableId = PayableInfo.ReceivableId) ReceivableTaxInfo
GROUP BY ContractId,GLTemplateId,IsSyndicated
INSERT INTO #SalesTaxGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'SalesTax',
GLTemplateId,
CASE WHEN IsSyndicated = 1 THEN 'SyndicatedSalesTaxReceivable' ELSE 'SalesTaxReceivable' END,
SalesTaxReceivableBalance,
1
FROM #SalesTaxEntryItemBalances S
WHERE SalesTaxReceivableBalance <> 0
INSERT INTO #SalesTaxGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'SalesTax',
GLTemplateId,
CASE WHEN IsSyndicated = 1 THEN 'PrePaidSyndicatedSalesTaxReceivable' ELSE 'PrePaidSalesTaxReceivable' END,
PrePaidSalesTaxReceivableBalance,
1
FROM #SalesTaxEntryItemBalances S
WHERE PrePaidSalesTaxReceivableBalance <> 0
INSERT INTO #SalesTaxGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'SalesTax',
GLTemplateId,
'SalesTaxPayable',
SUM(SalesTaxPayableBalance),
0
FROM #SalesTaxEntryItemBalances S
WHERE SalesTaxPayableBalance <> 0
GROUP BY ContractId,GLTemplateId
INSERT INTO #SalesTaxGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
ContractId,
'SalesTax',
GLTemplateId,
'UncollectedSalesTaxAR',
SUM(UncollectedSalesTaxARBalance),
0
FROM #SalesTaxEntryItemBalances S
WHERE UncollectedSalesTaxARBalance <> 0
GROUP BY ContractId,GLTemplateId
END
SELECT * FROM #SalesTaxGLSummary
IF OBJECT_ID ('tempdb..#SalesTaxGLSummary') IS NOT NULL
DROP TABLE #SalesTaxGLSummary
IF OBJECT_ID ('tempdb..#SalesTaxReceivableInfo') IS NOT NULL
DROP TABLE #SalesTaxReceivableInfo
IF OBJECT_ID ('tempdb..#SalesTaxEntryItemBalances') IS NOT NULL
DROP TABLE #SalesTaxEntryItemBalances
END

GO
