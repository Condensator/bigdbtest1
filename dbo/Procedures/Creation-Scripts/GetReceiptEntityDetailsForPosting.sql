SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetReceiptEntityDetailsForPosting](
@ReceiptIds ReceiptIdModel READONLY,
@JobStepInstanceId	BIGINT
)
AS
BEGIN
SET NOCOUNT ON;

CREATE TABLE #UpfrontDetails
(ReceiptId BIGINT,
ReceivableDetailId BIGINT,
UpfrontAmount DECIMAL(16,2));

SELECT Id INTO #ReceiptIds FROM @ReceiptIds
--Receipts Details
SELECT
Receipts.ReceiptId,
Receipts.ReceiptNumber,
Receipts.ContractId,
Receipts.LegalEntityId,
Receipts.LineofBusinessId,
Receipts.InstrumentTypeId,
Receipts.CostCenterId,
Receipts.BranchId,
Receipts.DiscountingId ,
Receipts.EntityType,
Receipts.ReceiptClassification,
Receipts.ReceiptGLTemplateId,
Receipts.CustomerId,
Receipts.ReceivedDate,
Receipts.PostDate,
Receipts.ReceiptAmount,
Receipts.BankAccountId,
Receipts.Currency,
Receipts.CurrencyId,
Receipts.ReceiptApplicationId,
Receipts.UnallocatedDescription,
Receipts.AcquisitionID,
Receipts.DealProductTypeId,
Receipts.ContractLegalEntityId,
Receipts.ReceiptType,
Receipts.SecurityDepositGLTemplateId,
Receipts.PPTEscrowGLTemplateId,
Receipts.SecurityDepositLiabilityAmount,
Receipts.SecurityDepositLiabilityContractAmount
FROM #ReceiptIds AS ReceiptIds
JOIN Receipts_Extract Receipts ON ReceiptIds.Id = Receipts.ReceiptId AND Receipts.JobStepInstanceId = @JobStepInstanceId



IF EXISTS (SELECT 1 FROM ReceiptUpfrontTaxDetails_Extract RUT
JOIN #ReceiptIds  Rid ON Rid.Id= RUT.ReceiptId WHERE RUT.JobStepInstanceId = @JobStepInstanceId)
BEGIN
INSERT  INTO #UpfrontDetails
SELECT RId.Id AS ReceiptId,RTD.ReceivableDetailId, SUM(AmountPosted_Amount) AS UpfrontAmount
FROM ReceiptUpfrontTaxDetails_Extract RUTD
JOIN #ReceiptIds RId on RId.Id= RUTD.ReceiptId
JOIN ReceiptReceivableDetails_Extract RARD ON RARD.ReceiptId = RId.Id  AND RARD.IsReApplication = 1 AND RARD.JObStepInstanceId= RUTD.JObstepInstanceId
JOIN ReceiptApplications RA ON RA.ReceiptId= Rid.Id
JOIN ReceiptApplicationReceivableTaxImpositions RARTI ON RARTI.ReceiptApplicationId = RA.Id AND RARTI.IsActive=1
JOIN ReceivableTaxImpositions RTI ON RTI.Id= RARTI.ReceivableTaxImpositionId AND RTI.TaxBasisType<>'ST'
AND RTI.TaxBasisType<>'_' AND RTI.IsActive=1
JOIN ReceivableTaxDetails RTD ON RTD.ID = RTI.ReceivableTaxDetailId AND RTD.IsActive=1 AND RARD.ReceivableDetailId = RTD.ReceivableDetailId
WHERE RUTD.JobStepInstanceId = @JobStepInstanceId
GROUP BY RId.Id,RTD.ReceivableDetailId


INSERT  INTO #UpfrontDetails
SELECT RId.Id AS ReceiptId,RTD.ReceivableDetailId, SUM(AmountPosted_Amount) AS UpfrontAmount
FROM ReceiptUpfrontTaxDetails_Extract RUTD
JOIN #ReceiptIds RId on RId.Id= RUTD.ReceiptId
JOIN ReceiptReceivableDetails_Extract RARD ON RARD.ReceiptId = RId.Id  AND RARD.IsReApplication = 0 AND RARD.JObStepInstanceId= RUTD.JObstepInstanceId
JOIN ReceiptApplicationReceivableTaxImpositions RARTI ON RARTI.ReceiptApplicationId = RARD.ReceiptApplicationId AND RARTI.IsActive=1
JOIN ReceivableTaxImpositions RTI ON RTI.Id= RARTI.ReceivableTaxImpositionId AND RTI.TaxBasisType<>'ST'
AND RTI.TaxBasisType<>'_' AND RTI.IsActive=1
JOIN ReceivableTaxDetails RTD ON RTD.ID = RTI.ReceivableTaxDetailId AND RTD.IsActive=1 AND RARD.ReceivableDetailId = RTD.ReceivableDetailId
WHERE RUTD.JobStepInstanceId = @JobStepInstanceId
GROUP BY RId.Id,RTD.ReceivableDetailId
END

--ReceiptApplicationReceivableDetails Details
SELECT
RARD.ReceiptApplicationReceivableDetailId,
RARD.ReceiptId,
RARD.ReceivableDetailId,
RARD.FunderId,
RARD.AmountApplied,
RARD.TaxApplied,
RARD.BookAmountApplied,
RARD.AmountApplied - RARD.PrevAmountAppliedForReApplication AS AmountToClear,
RARD.TaxApplied - RARD.PrevTaxAppliedForReApplication AS TaxAmountToClear,
RARD.BookAmountApplied - RARD.PrevBookAmountAppliedForReApplication AS BookAmountToClear,
RARD.ReceivableId,
RARD.IsChargeoffReceivable,
RARD.IsWritedownReceivable,
RARD.InvoiceId,
RARD.ContractId,
RARD.CustomerId,
RARD.DiscountingId,
RARD.ReceivableType,
RARD.AssetComponentType,
RARD.IsNegativeReceivable,
RARD.IsGLPosted,
RARD.IsTaxGLPosted,
RARD.ReceivableTypeId,
RARD.PaymentScheduleId,
RARD.IsTiedToDiscounting,
RARD.IsChargeoffContract,
RARD.IsWritedownContract,
RARD.IsSyndicatedContract,
RARD.IsSyndicated,
RARD.AlternateBillingCurrencyId,
RARD.ExchangeRate,
RARD.SequenceNumber,
RARD.DueDate,
RARD.LegalEntityId,
RARD.IsTaxCashBased,
RARD.SourceTable,
RARD.SourceId,
RARD.EntityType,
RARD.EntityId,
RARD.IncomeType,
RARD.GLTransactionType,
RARD.ReceivableBalance,
RARD.ReceivableDetailBalance,
RARD.ReceivableTotalAmount,
RARD.ReceivableGLTemplateId,
RARD.SyndicationGLTemplateId,
RARD.AccountingTreatment,
RARD.IsIntercompany,
RARD.ReceivableTaxGLTemplateId,
RARD.ClearingAPGLTemplateId,
RARD.InstrumentTypeId,
RARD.CostCenterId,
RARD.LineofBusinessId,
RARD.BranchId,
RARD.DealProductTypeId,
RARD.AcquisitionId,
RARD.ContractType,
RARD.NonAccrualDate,
RARD.AssetId,
RARD.IsNonAccrual,
RARD.IncomeGLTemplateId,
RARD.PaymentScheduleStartDate,
RARD.LeaseContractType,
RARD.AccountingStandard,
RARD.CurrentFinanceId,
RARD.IsLeaseAsset,
RARD.DoubtfulCollectability,
RARD.ReceiptApplicationId,
RARD.IsReApplication,
RARD.PrevPrePaidForReApplication,
RARD.PrevPrePaidTaxForReApplication,
RARD.LeaseBookingGLTemplateId,
RARD.LeaseInterimInterestIncomeGLTemplateId,
RARD.LeaseInterimRentIncomeGLTemplateId,
RARD.LeveragedLeaseBookingGLTemplateId,
RARD.LoanInterimIncomeRecognitionGLTemplateId,
RARD.LoanBookingGLTemplateId,
RARD.LoanIncomeRecognitionGLTemplateId,
RARD.CommencementDate,
RARD.PrepaidReceivableId,
RARD.CurrentPrepaidAmount,
RARD.CurrentPrepaidFinanceAmount,
RARD.CurrentPrepaidTaxAmount,
RARD.AdjustedWithHoldingTax AS AdjustedWithHoldingTax,
RARD.AdjustedWithHoldingTax - RARD.PrevAdjustedWithHoldingTaxForReApplication AS AdjustedWithHoldingTaxToClear,
RARD.LeaseComponentAmountApplied,
RARD.NonLeaseComponentAmountApplied,
RARD.LeaseComponentAmountApplied - RARD.PrevLeaseComponentAmountAppliedForReApplication AS LeaseComponentAmountToClear,
RARD.NonLeaseComponentAmountApplied - RARD.PrevNonLeaseComponentAmountAppliedForReApplication AS NonLeaseComponentAmountToClear,
RARD.PrevPrePaidLeaseComponentForReApplication,
RARD.PrevPrePaidNonLeaseComponentForReApplication,
RARD.WithHoldingTaxBookAmountApplied AS WithHoldingTaxBookAmountApplied,
CAST(ISNULL(URD.UpfrontAmount,0) AS Decimal(16,2)) AS UpfrontPayableAmount
FROM #ReceiptIds AS ReceiptIds
JOIN ReceiptReceivableDetails_Extract RARD ON RARD.ReceiptId = ReceiptIds.Id AND RARD.JobStepInstanceId = @JobStepInstanceId
LEFT JOIN #UpfrontDetails URD ON URD.ReceiptId = RARD.ReceiptId AND RARD.ReceivableDetailId = URD.ReceivableDetailId 

--Unapplied Receipt Details
SELECT ReceiptId,
CurrentAmountApplied,
AllocationReceiptId,
OriginalReceiptBalance,
ReceiptAllocationId,
OriginalAllocationAmountApplied,
EntityType,
ContractId,
DiscountingId,
CustomerId,
LegalEntityId,
LineOfBusinessId,
CostCenterId,
InstrumentTypeId,
BranchId,
BankAccountId,
ContractLegalEntityId,
AcquisitionId,
DealProductTypeId,
ReceiptGLTemplateId,
Currency
FROM #ReceiptIds AS ReceiptIds
JOIN UnappliedReceipts_Extract ON ReceiptIds.Id = UnappliedReceipts_Extract.ReceiptId AND UnappliedReceipts_Extract.JobStepInstanceId = @JobStepInstanceId
DROP TABLE #ReceiptIds
END

GO
