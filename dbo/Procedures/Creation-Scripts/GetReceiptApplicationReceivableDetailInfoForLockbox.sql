SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetReceiptApplicationReceivableDetailInfoForLockbox]
@LegalEntityId BIGINT,
@ReceiptCustomerId BIGINT,
@ReceiptContractId BIGINT,
@CurrentUserId BIGINT,
@CurrencyISO NVARCHAR(6),
@InvoiceIdsToSelect InvoiceIdCollection READONLY
AS
BEGIN
DECLARE @AccessibleLegalEntity table(LegalEntityId bigint)
DECLARE @InvoiceIdsToSelectTemp table (InvoiceId bigint)
INSERT INTO @AccessibleLegalEntity(LegalEntityId)
SELECT LegalEntities.Id AS LegalEntityId
FROM
LegalEntities
JOIN LegalEntitiesForUsers ON LegalEntities.Id = LegalEntitiesForUsers.LegalEntityId
AND LegalEntitiesForUsers.IsActive = 1
AND LegalEntitiesForUsers.UserId = @CurrentUserId
--AND LegalEntities.Id = @LegalEntityId
GROUP BY LegalEntities.Id
INSERT INTO @InvoiceIdsToSelectTemp
SELECT InvoiceId
FROM @InvoiceIdsToSelect
DECLARE @LoanInterestReceivableTypeId BIGINT;
DECLARE @LoanPrincipalReceivableTypeId BIGINT;
SELECT @LoanInterestReceivableTypeId = Id FROM ReceivableTypes WHERE Name = 'LoanInterest'
SELECT @LoanPrincipalReceivableTypeId = Id FROM ReceivableTypes WHERE Name = 'LoanPrincipal'
--#ReceivableDetailIds
SELECT
ReceivableDetailId
INTO #ReceivableDetailIds
FROM
@InvoiceIdsToSelectTemp AS Invoice
JOIN ReceivableInvoiceDetails ON ReceivableInvoiceDetails.ReceivableInvoiceId = Invoice.InvoiceId
JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive = 1
AND ReceivableInvoices.IsDummy = 0
AND ReceivableInvoiceDetails.IsActive = 1
JOIN @AccessibleLegalEntity AS AccessibleLegalEntity ON AccessibleLegalEntity.LegalEntityId = ReceivableInvoices.LegalEntityId
JOIN ReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id and ReceivableDetails.IsActive=1
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
AND Receivables.IsDummy = 0
AND Receivables.IsCollected = 1
JOIN Customers ON Receivables.CustomerId = Customers.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
LEFT JOIN Contracts ON Contracts.Id = ReceivableInvoiceDetails.EntityId AND ReceivableInvoiceDetails.EntityType = 'CT'
WHERE
(ReceivableInvoiceDetails.EffectiveBalance_Amount + ReceivableInvoiceDetails.EffectiveTaxBalance_Amount) <> 0 AND
((Contracts.Id IS NULL OR Contracts.ContractType != 'Loan' OR Contracts.IsNonAccrual = 0)
OR (Receivables.IncomeType IN ('InterimInterest','TakeDownInterest'))
OR (ReceivableCodes.ReceivableTypeId != @LoanInterestReceivableTypeId AND ReceivableCodes.ReceivableTypeId != @LoanPrincipalReceivableTypeId))
AND (@ReceiptCustomerId IS NUll  OR Customers.Id = @ReceiptCustomerId)
AND (@ReceiptContractId IS NULL OR Contracts.Id = @ReceiptContractId)
;
--#ReceivableTaxDetailInfo
SELECT
#ReceivableDetailIds.ReceivableDetailId,
ReceivableTaxDetails.IsGLPosted
INTO #ReceivableTaxDetailInfo
FROM #ReceivableDetailIds
INNER JOIN ReceivableTaxDetails ON ReceivableTaxDetails.ReceivableDetailId = #ReceivableDetailIds.ReceivableDetailId AND ReceivableTaxDetails.IsActive = 1
INNER JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id AND ReceivableTaxes.IsActive = 1
GROUP BY #ReceivableDetailIds.ReceivableDetailId,ReceivableTaxDetails.IsGLPosted
--Final Select
SELECT
ReceivableDetails.AssetId AS AssetId,
Receivables.Id AS ReceivableId,
ReceivableDetails.Id AS ReceivableDetailId,
ReceivableInvoices.Id AS ReceivableInvoiceId,
Receivables.CustomerId AS CustomerId,
Contracts.Id AS ContractId,
Discountings.Id AS DiscountingId,
Receivables.DueDate AS DueDate,
ReceivableTypes.Name AS ReceivableType,
ReceivableInvoiceDetails.InvoiceAmount_Amount AS ReceivableAmount,
ReceivableInvoiceDetails.Balance_Amount AS ReceivableBalance,
ReceivableInvoiceDetails.EffectiveBalance_Amount AS EffectiveReceivableBalance,
Receivables.TotalBalance_Amount AS TotalReceivableBalance,
ReceivableInvoiceDetails.InvoiceTaxAmount_Amount AS TaxAmount,
ReceivableInvoiceDetails.TaxBalance_Amount AS TaxBalance,
ReceivableInvoiceDetails.EffectiveTaxBalance_Amount AS EffectiveTaxBalance,
ReceivableDetails.Amount_Currency AS Currency,
ReceivableTypes.Id AS ReceivableTypeId,
ReceivableCodes.Id AS ReceivableCodeId,
ReceivableCodes.AccountingTreatment AS AccountingTreatment,
ISNULL(LegalEntities.TaxRemittancePreference,'_') AS LegalEntityTaxRemittancePreference,
ISNULL(Contracts.SalesTaxRemittanceMethod,'_') AS ContractTaxRemittancePreference,
ReceivableCodes.GLTemplateId AS GLTemplateId,
ReceivableCodes.SyndicationGLTemplateId AS SyndicationGLTemplateId,
Receivables.FunderId AS FunderId,
Receivables.IsGLPosted AS IsGLPosted,
ISNULL(TaxDetails.IsGLPosted, CAST(0 AS BIT)) AS IsTaxGLPosted,
ReceivableTypes.IsRental AS IsRental,
GLTransactionTypes.Name AS GLTransactionType,
ISNULL(Contracts.ContractType,'_') AS ContractType,
ISNULL(Contracts.SyndicationType,'_') AS SyndicationType,
ReceivableCodes.Name AS ReceivableCodeName,
Receivables.EntityType AS ReceivableEntityType,
Receivables.SourceId AS SourceId,
Receivables.SourceTable AS SourceTable,
ISNULL(Contracts.ChargeOffStatus,'_') AS ChargeOffStatus,
Receivables.PaymentScheduleId AS PaymentScheduleId,
ISNULL(Receivables.IncomeType,'_') AS IncomeType,
CASE WHEN Contracts.ContractType = 'Lease' THEN ISNULL(LeasePaymentSchedules.PaymentType,'_') ELSE ISNULL(LoanPaymentSchedules.PaymentType,'_') END AS PaymentType,
LeasePaymentSchedules.LeaseFinanceDetailId AS ReceivableLeaseFinanceId,
LegalEntities.LateFeeApproach AS LegalEntityLateFeeApproach,
LegalEntities.Id AS LegalEntityId,
LegalEntities.LegalEntityNumber AS LegalEntityNumber,
CASE WHEN Contracts.ContractType = 'Lease' THEN LeaseFinances.InstrumentTypeId ELSE LoanFinances.InstrumentTypeId END AS InstrumentTypeId,
CASE WHEN Contracts.ContractType = 'Lease' THEN LeaseFinances.LineofBusinessId ELSE LoanFinances.LineofBusinessId END AS LineofBusinessId,
CASE WHEN Contracts.ContractType = 'Lease' THEN LeaseFinances.CostCenterId ELSE LoanFinances.CostCenterId END AS CostCenterId,
CASE WHEN Contracts.ContractType = 'Lease' THEN LeaseFinances.BranchId ELSE LoanFinances.BranchId END AS BranchId,
Parties.IsIntercompany AS IsIntercompany,
CASE WHEN ReceivableDetails.AdjustmentBasisReceivableDetailId IS NOT NULL OR AdjustmentReceivableDetail.AdjustmentBasisReceivableDetailId IS NOT NULL
THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsAdjustmentDetail,
ReceivableDetails.AssetComponentType,
ChargeOffs.ChargeOffDate as ChargeoffDate
FROM
#ReceivableDetailIds
JOIN ReceivableDetails ON #ReceivableDetailIds.ReceivableDetailId = ReceivableDetails.Id
JOIN ReceivableInvoiceDetails ON ReceivableDetails.Id = ReceivableInvoiceDetails.ReceivableDetailId
AND ReceivableInvoiceDetails.IsActive = 1
JOIN  ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id
AND ReceivableInvoices.IsActive = 1
AND ReceivableInvoices.IsDummy = 0
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
JOIN Parties ON Receivables.CustomerId = Parties.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN GLTransactionTypes ON ReceivableTypes.GLTransactionTypeId = GLTransactionTypes.Id
JOIN LegalEntities ON Receivables.LegalEntityId = LegalEntities.Id
LEFT JOIN Contracts ON Receivables.EntityId = Contracts.Id AND Receivables.EntityType = 'CT'
LEFT JOIN Discountings ON Receivables.EntityId = Discountings.Id AND Receivables.EntityType = 'DT'
LEFT JOIN ChargeOffs ON ChargeOffs.ContractId=Contracts.Id AND ChargeOffs.IsActive=1 AND ChargeOffs.Status='Approved' AND ChargeOffs.ReceiptId IS NULL
LEFT JOIN ReceivableDetails AdjustmentReceivableDetail ON ReceivableDetails.Id = AdjustmentReceivableDetail.AdjustmentBasisReceivableDetailId AND AdjustmentReceivableDetail.IsActive=1
LEFT JOIN #ReceivableTaxDetailInfo TaxDetails ON ReceivableDetails.Id = TaxDetails.ReceivableDetailId
LEFT JOIN LeasePaymentSchedules ON Contracts.ContractType = 'Lease' AND Receivables.PaymentScheduleId = LeasePaymentSchedules.Id
LEFT JOIN LoanPaymentSchedules ON Contracts.ContractType = 'Loan' AND Receivables.PaymentScheduleId = LoanPaymentSchedules.Id
LEFT JOIN LeaseFinances ON Contracts.ContractType = 'Lease' AND LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
LEFT JOIN LoanFinances ON (Contracts.ContractType = 'Loan' OR Contracts.ContractType = 'ProgressLoan') AND LoanFinances.ContractId = Contracts.Id AND LoanFinances.IsCurrent = 1
DROP TABLE #ReceivableDetailIds;
DROP TABLE #ReceivableTaxDetailInfo
END

GO
