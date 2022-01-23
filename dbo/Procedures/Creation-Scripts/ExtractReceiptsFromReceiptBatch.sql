SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ExtractReceiptsFromReceiptBatch]
(
@CreatedById										BIGINT,
@CreatedTime										DATETIMEOFFSET,
@JobStepInstanceId									BIGINT,
@PostDate											DATE,
@ReceivableEntityTypeValues_CT						NVARCHAR(10),
@ReceivableEntityTypeValues_DT						NVARCHAR(10),
@ReceiptBatchIdParameter ReceiptBatchIdParameter	READONLY,
@ReceiptClassificationValue_DSL						NVARCHAR(3),
@ReceiptAllocationEntityTypeValues_UnAllocated		NVARCHAR(14),
@ReceiptStatus_Posted								NVARCHAR(40)
)
AS
BEGIN
SET NOCOUNT ON;
INSERT INTO Receipts_Extract
(ReceiptId, ReceiptNumber, Currency, PostDate, ReceivedDate, ReceiptClassification, LegalEntityId, ReceiptBatchId, IsValid,
JobStepInstanceId, CreatedById, CreatedTime, LineOfBusinessId, CostCenterId,InstrumentTypeId,BranchId, ContractId, DiscountingId, EntityType, ReceiptGLTemplateId, CustomerId, ReceiptAmount,BankAccountId,ReceiptApplicationId,UnallocatedDescription,CurrencyId, IsNewReceipt)
SELECT
RBD.ReceiptId
,R.Number ReceiptNumber
,R.Balance_Currency Currency
,@PostDate
,R.ReceivedDate
,R.ReceiptClassification
,R.LegalEntityId
,RB.Id AS ReceiptBatchId
,CAST(1 AS BIT) IsValid
,@JobStepInstanceId
,@CreatedById
,@CreatedTime
,R.LineofBusinessId
,R.CostCenterId
,R.InstrumentTypeId
,R.BranchId
,R.ContractId
,R.DiscountingId
,R.EntityType
,R.ReceiptGLTemplateId
,R.CustomerId
,R.ReceiptAmount_Amount ReceiptAmount
,R.BankAccountId
,RA.Id ReceiptApplicationId
,RAL.[Description] UnallocatedDescription
,R.CurrencyId
,CAST(0 AS BIT) IsNewReceipt
FROM ReceiptBatches RB
INNER JOIN @ReceiptBatchIdParameter RBID ON RB.Id = RBID.Id
INNER JOIN ReceiptBatchDetails RBD ON RB.Id = RBD.ReceiptBatchId AND RBD.IsActive = 1
INNER JOIN Receipts R ON RBD.ReceiptId = R.Id AND R.Status <> @ReceiptStatus_Posted
INNER JOIN ReceiptApplications RA ON R.Id = RA.ReceiptId
LEFT JOIN ReceiptAllocations RAL ON R.Id = RAL.ReceiptId AND RAL.IsActive = 1
AND RAL.EntityType = @ReceiptAllocationEntityTypeValues_UnAllocated
WHERE R.ReceiptClassification <> @ReceiptClassificationValue_DSL
;
INSERT INTO ReceiptApplicationReceivableDetails_Extract
(ReceiptId, AmountApplied, AdjustedWithHoldingTax, TaxApplied,BookAmountApplied, WithHoldingTaxBookAmountApplied, ReceivableDetailId, JobStepInstanceId, ReceivableDetailIsActive, InvoiceId,
ContractId, DiscountingId, CreatedById, CreatedTime, ReceivableId, ReceiptApplicationId, ReceiptApplicationReceivableDetailId, IsReApplication,
LeaseComponentAmountApplied, NonLeaseComponentAmountApplied, ReceivedTowardsInterest)
SELECT
R.ReceiptId
,RARD.AmountApplied_Amount AmountApplied
,RARD.AdjustedWithholdingTax_Amount AdjustedWithHoldingTax
,RARD.TaxApplied_Amount TaxApplied
,RARD.BookAmountApplied_Amount BookAmountApplied
,RARD.WithHoldingTaxBookAmountApplied_Amount WithHoldingTaxBookAmountApplied
,RARD.ReceivableDetailId
,@JobStepInstanceId
,RD.IsActive ReceivableDetailIsActive
,RID.ReceivableInvoiceId
,CASE WHEN RS.EntityType = @ReceivableEntityTypeValues_CT THEN RS.EntityId ELSE NULL END AS ContractId
,CASE WHEN RS.EntityType = @ReceivableEntityTypeValues_DT THEN RS.EntityId ELSE NULL END AS DiscountingId
,@CreatedById
,@CreatedTime
,RS.Id
,RA.Id
,RARD.Id
,RARD.IsReApplication
,RARD.LeaseComponentAmountApplied_Amount AS LeaseComponentAmountApplied
,RARD.NonLeaseComponentAmountApplied_Amount AS NonLeaseComponentAmountApplied
,RARD.ReceivedTowardsInterest_Amount
FROM Receipts_Extract R
INNER JOIN ReceiptApplications RA ON R.ReceiptId = RA.ReceiptId AND R.JobStepInstanceId = @JobStepInstanceId AND  R.IsNewReceipt = 0
INNER JOIN ReceiptApplicationReceivableDetails RARD ON RA.Id = RARD.ReceiptApplicationId AND RARD.IsActive = 1
INNER JOIN ReceivableDetails RD ON RARD.ReceivableDetailId = RD.Id
INNER JOIN Receivables RS ON RD.ReceivableId = RS.Id
INNER JOIN ReceivableCodes RC on RS.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT on RC.ReceivableTypeId = RT.Id
LEFT JOIN ReceivableInvoiceDetails RID ON RD.Id = RID.ReceivableDetailId AND RID.IsActive = 1
LEFT JOIN ReceivableInvoices RI ON RID.ReceivableInvoiceId = RI.Id AND RI.IsActive = 1
WHERE RI.Id IS NULL OR RI.IsDummy = 0


INSERT INTO UnappliedReceipts_Extract ([ReceiptId],[Currency],[BankAccountId],[CreatedById],[CreatedTime],[CurrentAmountApplied],[AllocationReceiptId],[OriginalReceiptBalance],[ReceiptAllocationId],
[OriginalAllocationAmountApplied],[EntityType],[ContractId],[DiscountingId],[CustomerId],[LegalEntityId],[LineOfBusinessId],[CostCenterId],
[InstrumentTypeId],[BranchId],[ContractLegalEntityId],[AcquisitionId],[DealProductTypeId],[ReceiptGLTemplateId],[JobStepInstanceId])
SELECT
R.ReceiptId [ReceiptId],
AR.ReceiptAmount_Currency [Currency],
AR.BankAccountId [BankAccountId],
@CreatedById [CreatedById],
@CreatedTime [CreatedTime],
UR.AmountApplied_Amount [CurrentAmountApplied],
RA.ReceiptId [AllocationReceiptId],
AR.Balance_Amount [OriginalReceiptBalance],
RA.Id [ReceiptAllocationId],
RA.AmountApplied_Amount [OriginalAllocationAmountApplied],
AR.EntityType [EntityType],
AR.[ContractId],
AR.[DiscountingId],
AR.[CustomerId],
AR.[LegalEntityId],
AR.[LineOfBusinessId],
AR.[CostCenterId],
AR.[InstrumentTypeId],
AR.[BranchId],
CASE WHEN Lease.Id IS NOT NULL THEN Lease.LegalEntityId
WHEN Loan.Id IS NOT NULL THEN Loan.LegalEntityId
WHEN LevLease.Id IS NOT NULL THEN LevLease.LegalEntityId
ELSE NULL END [ContractLegalEntityId],
CASE WHEN Lease.Id IS NOT NULL THEN Lease.[AcquisitionId]
WHEN Loan.Id IS NOT NULL THEN Loan.[AcquisitionId]
WHEN LevLease.Id IS NOT NULL THEN LevLease.[AcquisitionId]
ELSE NULL END [AcquisitionId],
C.[DealProductTypeId],
AR.[ReceiptGLTemplateId],
@JobStepInstanceId
FROM (SELECT ReceiptId FROM Receipts_Extract WHERE JobStepInstanceId = @JobStepInstanceId
AND IsNewReceipt = 0) R
JOIN UnappliedReceipts UR ON R.ReceiptId = UR.ReceiptId AND UR.IsActive = 1
JOIN ReceiptAllocations RA ON UR.ReceiptAllocationId = RA.Id AND RA.IsActive = 1
JOIN Receipts AR ON RA.ReceiptId = AR.Id
LEFT JOIN Contracts C ON AR.ContractId = C.Id
LEFT JOIN LeaseFinances Lease ON C.Id = Lease.ContractId AND Lease.IsCurrent = 1
LEFT JOIN LoanFinances Loan ON C.Id = Loan.ContractId AND Loan.IsCurrent = 1
LEFT JOIN LeveragedLeases LevLease ON C.Id = LevLease.ContractId AND LevLease.IsCurrent = 1
LEFT JOIN DiscountingFinances DF ON AR.DiscountingId = DF.DiscountingId AND DF.IsCurrent = 1
SELECT Count(*) AS Id FROM Receipts_Extract WHERE JobStepInstanceId = @JobStepInstanceId
END

GO
