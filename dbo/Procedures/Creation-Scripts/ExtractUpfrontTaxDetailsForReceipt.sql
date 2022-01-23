SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ExtractUpfrontTaxDetailsForReceipt]
(
@CreatedById										BIGINT,
@CreatedTime										DATETIMEOFFSET,
@JobStepInstanceId									BIGINT,
@SalesTaxRemittanceResponsibilityValues_Vendor      NVARCHAR(8),
@TaxBasisTypeValues_UC								NVARCHAR(2),
@TaxBasisTypeValues_UR								NVARCHAR(2)
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
;With CTE_ContractsToFilter(ReceiptId,ContractId,AssetId) AS
(
SELECT ReceiptId,ContractId,AssetId
FROM ReceiptReceivableDetails_Extract
where JobStepInstanceId = @JobStepInstanceId AND TaxApplied <> 0 AND IsTaxCashBased = 1 AND IsAdjustmentReceivableDetail = 0
GROUP BY ReceiptId,ContractId,AssetId
)
INSERT INTO ReceiptUpfrontTaxDetails_Extract(ReceiptId, ContractId, AssetId, LeaseAssetSalesTaxResposibillity, SalesTaxResposibillityFromHistories, EffectiveTillDate, VendorId, PayableCodeId, LeaseAssetVendorRemitToId, VendorRemitToIdFromHistories, JobStepInstanceId, CreatedById, CreatedTime)
SELECT C.ReceiptId,
C.ContractId,
C.AssetId,
LA.SalesTaxRemittanceResponsibility LeaseAssetSalesTaxResposibillity,
STRH.SalesTaxRemittanceResponsibility SalesTaxResposibillityFromHistories,
EffectiveTillDate,
VendorId,
LF.VendorPayableCodeId PayableCodeId,
LA.VendorRemitToId LeaseAssetVendorRemitToId,
STRH.VendorRemitToId VendorRemitToIdFromHistories,
@JobStepInstanceId,
@CreatedById,
@CreatedTime
FROM CTE_ContractsToFilter C
JOIN LeaseFinances LF ON C.ContractId = LF.ContractId AND LF.IsCurrent=1
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id AND LFD.CapitalizeUpfrontSalesTax = 0
JOIN PayableInvoiceAssets PIA ON C.AssetId = PIA.AssetId AND PIA.IsActive = 1
JOIN PayableInvoices PI ON PIA.PayableInvoiceId = PI.Id AND PI.ParentPayableInvoiceId IS NULL
JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id AND C.AssetId = LA.AssetId AND LA.IsActive =1
JOIN LeaseTaxAssessmentDetails LTA ON LA.LeaseTaxAssessmentDetailId = LTA.Id
JOIN TaxBasisTypes TBT ON LTA.TaxBasisTypeId = TBT.Id AND (TBT.Name = @TaxBasisTypeValues_UC OR TBT.Name = @TaxBasisTypeValues_UR)
LEFT JOIN ContractSalesTaxRemittanceResponsibilityHistories STRH ON STRH.AssetId = C.AssetId AND LF.ContractId =STRH.ContractId
WHERE STRH.SalesTaxRemittanceResponsibility = @SalesTaxRemittanceResponsibilityValues_Vendor OR LA.SalesTaxRemittanceResponsibility = @SalesTaxRemittanceResponsibilityValues_Vendor
GROUP BY C.ReceiptId, C.ContractId, C.AssetId, LA.SalesTaxRemittanceResponsibility, STRH.SalesTaxRemittanceResponsibility, STRH.EffectiveTillDate, VendorId, LF.VendorPayableCodeId, LA.VendorRemitToId, STRH.VendorRemitToId
END

GO
