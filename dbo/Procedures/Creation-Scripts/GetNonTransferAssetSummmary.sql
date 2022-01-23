SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--IF(TYPE_ID('AssetIdList') IS NOT NULL)
--	DROP TYPE AssetIdList;
--GO
--CREATE TYPE AssetIdList AS TABLE
--(
--	AssetId BIGINT NOT NULL
--)
--GO
CREATE PROCEDURE [dbo].[GetNonTransferAssetSummmary]
(
@DirectlyImportedAssetIds AssetIdList READONLY,
@PayableInvoiceImportedAssetIds AssetIdList READONLY,
@LeaseFinanceId BIGINT,
@StandaloneValue NVARCHAR(10),
@ApprovedStatusValue NVARCHAR(8),
@PayableInvoiceAssetValue NVARCHAR(19),
@CompletedValue NVARCHAR(9),
@InventoryAssetStatusValue NVARCHAR(9),
@PaydownActiveStatusValue NVARCHAR(6),
@PaydownRepossessionValue NVARCHAR(12),
@InactivePayableInvoiceStatus NVARCHAR(10),
@AssetValueAdjustmentValue NVARCHAR(25),
@IsRestructure BIT,
@ProgressPaymentCreditValue NVARCHAR(21)
)
AS
SELECT * INTO #NonTransferAssetIds FROM @DirectlyImportedAssetIds
SELECT * INTO #PIAssetIds FROM @PayableInvoiceImportedAssetIds
ALTER TABLE #NonTransferAssetIds ADD PRIMARY KEY (AssetId)
ALTER TABLE #PIAssetIds ADD PRIMARY KEY(AssetId)
CREATE TABLE #NonTransferAssetSummary
(
AssetId BIGINT,
ETCAdjustmentAmount DECIMAL(16,2),
InventoryGLTemplateId BIGINT,
InstrumentTypeId BIGINT,
LineofBusinessId BIGINT,
CostCenterId BIGINT,
BranchId BIGINT,
Amount DECIMAL(16,2),
Type NVARCHAR(15),
IsFromPaydown BIT,
ExcludeGLSegmentValue BIT)
CREATE TABLE #InventorySummary
(
AssetId BIGINT,
ETCAdjustmentAmount DECIMAL(16,2),
InventoryGLTemplateId BIGINT,
InstrumentTypeId BIGINT,
LineofBusinessId BIGINT,
CostCenterId BIGINT,
BranchId BIGINT,
Amount DECIMAL(16,2),
Type NVARCHAR(15),
ExcludeGLSegmentValue BIT)
BEGIN
SELECT
DISTINCT
Payables.SourceId as PaidPIAssetId
INTO #PaidPayables
FROM
Payables
JOIN DisbursementRequestPayables ON Payables.Id = DisbursementRequestPayables.PayableId
JOIN DisbursementRequests ON DisbursementRequestPayables.DisbursementRequestId = DisbursementRequests.Id
WHERE
DisbursementRequests.OriginationType = @StandaloneValue
AND Payables.Status = @ApprovedStatusValue
AND Payables.SourceTable = @PayableInvoiceAssetValue
AND DisbursementRequestPayables.IsActive = 1
AND DisbursementRequests.Status = @CompletedValue
If EXISTS(SELECT TOP 1 * FROM #NonTransferAssetIds)
BEGIN
INSERT INTO #NonTransferAssetSummary(AssetId,ETCAdjustmentAmount,InventoryGLTemplateId,InstrumentTypeId,LineofBusinessId,CostCenterId,Amount,Type,IsFromPaydown,ExcludeGLSegmentValue)
SELECT
#NonTransferAssetIds.AssetId,
LeaseAssets.ETCAdjustmentAmount_Amount,
LoanPaydowns.PaydownGLTemplateId,
LoanFinances.InstrumentTypeId,
LoanFinances.LineofBusinessId,
LoanFinances.CostCenterId,
(LeaseAssets.NBV_Amount - LeaseAssets.CapitalizedInterimInterest_Amount - LeaseAssets.CapitalizedInterimRent_Amount - LeaseAssets.CapitalizedProgressPayment_Amount - LeaseASsets.CapitalizedSalesTax_Amount) as Amount,
'Origination',
1,
0
FROM
LoanPaydownAssetDetails
JOIN #NonTransferAssetIds ON LoanPaydownAssetDetails.AssetId = #NonTransferAssetIds.AssetId
JOIN LeaseAssets ON #NonTransferAssetIds.AssetId = LeaseAssets.AssetId AND LeaseFinanceId = @LeaseFinanceId
JOIN
(
SELECT #NonTransferAssetIds.AssetId,MAX(LoanFinanceId) as MaxLoanFinanceId,MAX(LoanPayDowns.Id) as MaxLoanPaydownId
FROM
LoanPaydownAssetDetails
JOIN #NonTransferAssetIds ON LoanPaydownAssetDetails.AssetId = #NonTransferAssetIds.AssetId
JOIN LoanPaydowns ON LoanPaydownAssetDetails.LoanPaydownId = LoanPaydowns.Id
AND LoanPaydownAssetDetails.IsActive = 1 AND LoanPaydowns.Status = @PaydownActiveStatusValue
AND LoanPaydownAssetDetails.AssetPaydownStatus = @InventoryAssetStatusValue
AND LoanPaydowns.PaydownReason = @PaydownRepossessionValue
GROUP BY #NonTransferAssetIds.AssetId
) AS LoanPaydownInfo ON #NonTransferAssetIds.AssetId = LoanPaydownInfo.AssetId
JOIN LoanPaydowns ON LoanPaydownInfo.MaxLoanPaydownId = LoanPaydowns.Id
JOIN LoanFinances ON LoanPaydownInfo.MaxLoanFinanceId = LoanFinances.Id
WHERE
LoanPaydownAssetDetails.IsActive =1
AND LoanPaydownAssetDetails.AssetPaydownStatus = @InventoryAssetStatusValue
INSERT INTO #NonTransferAssetSummary(AssetId,ETCAdjustmentAmount,InventoryGLTemplateId,InstrumentTypeId,LineofBusinessId,CostCenterId,BranchId,Amount,Type,IsFromPaydown,ExcludeGLSegmentValue)
SELECT
LeaseAssets.AssetId,
LeaseAssets.ETCAdjustmentAmount_Amount,
PayableCodes.GLTemplateId,
CASE WHEN PayableInvoiceInfo.InstrumentTypeId IS NOT NULL THEN PayableInvoiceInfo.InstrumentTypeId ELSE LeaseFinances.InstrumentTypeId END as InstrumentTypeId,
CASE WHEN PayableInvoiceInfo.LineofBusinessId IS NOT NULL THEN PayableInvoiceInfo.LineofBusinessId ELSE LeaseFinances.LineofBusinessId END as LineofBusinessId,
CASE WHEN PayableInvoiceInfo.CostCenterId IS NOT NULL THEN PayableInvoiceInfo.CostCenterId ELSE LeaseFinances.CostCenterId END as CostCenterId,
CASE WHEN PayableInvoiceInfo.BranchId IS NOT NULL THEN PayableInvoiceInfo.BranchId ELSE LeaseFinances.BranchId END as BranchId,
(LeaseAssets.NBV_Amount - LeaseAssets.CapitalizedInterimInterest_Amount - LeaseAssets.CapitalizedInterimRent_Amount - LeaseAssets.CapitalizedProgressPayment_Amount - LeaseASsets.CapitalizedSalesTax_Amount) as Amount,
'Origination',
0,
CASE WHEN #PaidPayables.PaidPIAssetId IS NOT NULL THEN 1 ELSE 0 END
FROM
PayableInvoiceAssets
JOIN #NonTransferAssetIds ON PayableInvoiceAssets.AssetId = #NonTransferAssetIds.AssetId
JOIN LeaseAssets ON #NonTransferAssetIds.AssetId = LeaseAssets.AssetId
JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND LeaseFinances.Id = @LeaseFinanceId
JOIN
(SELECT
#NonTransferAssetIds.AssetId,PayableInvoices.AssetCostPayableCodeId,PayableInvoices.LineofBusinessId,PayableInvoices.InstrumentTypeId,PayableInvoices.CostCenterId,
PayableInvoices.BranchId,MAX(PayableInvoices.ID) as MaxPIId
FROM
PayableInvoiceAssets
JOIN #NonTransferAssetIds ON PayableInvoiceAssets.AssetId = #NonTransferAssetIds.AssetId
JOIN PayableInvoices ON PayableInvoiceAssets.PayableInvoiceId = PayableInvoices.Id
AND PayableInvoiceAssets.IsActive = 1
AND PayableInvoices.Status <> @InactivePayableInvoiceStatus
GROUP BY #NonTransferAssetIds.AssetId,PayableInvoices.AssetCostPayableCodeId,PayableInvoices.LineofBusinessId,PayableInvoices.InstrumentTypeId,PayableInvoices.CostCenterId,
PayableInvoices.BranchId) as PayableInvoiceInfo ON PayableInvoiceAssets.PayableInvoiceId = PayableInvoiceInfo.MaxPIId
JOIN PayableCodes ON PayableInvoiceInfo.AssetCostPayableCodeId = PayableCodes.Id
LEFT JOIN #PaidPayables ON PayableInvoiceAssets.Id = #PaidPayables.PaidPIAssetId
LEFT JOIN #NonTransferAssetSummary ON #NonTransferAssetIds.AssetId = #NonTransferAssetSummary.AssetId
WHERE
#NonTransferAssetSummary.AssetId IS NULL
AND PayableInvoiceAssets.IsActive = 1
AND LeaseAssets.IsActive = 1
INSERT INTO #NonTransferAssetSummary(AssetId,ETCAdjustmentAmount,InventoryGLTemplateId,InstrumentTypeId,LineofBusinessId,CostCenterId,BranchId,Amount,Type,IsFromPaydown,ExcludeGLSegmentValue)
SELECT
AssetsValueStatusChangeDetails.AssetId,
LeaseAssets.ETCAdjustmentAmount_Amount,
MAX(AssetsValueStatusChangeDetails.GLTemplateId),
AssetsValueStatusChangeDetails.InstrumentTypeId,
AssetsValueStatusChangeDetails.LineofBusinessId,
AssetsValueStatusChangeDetails.CostCenterId,
NULL,
(LeaseAssets.NBV_Amount - LeaseAssets.CapitalizedInterimInterest_Amount - LeaseAssets.CapitalizedInterimRent_Amount - LeaseAssets.CapitalizedProgressPayment_Amount - LeaseASsets.CapitalizedSalesTax_Amount) as Amount,
'Origination',
0,
1
FROM
#NonTransferAssetIds
JOIN AssetValueHistories ON #NonTransferAssetIds.AssetId = AssetValueHistories.AssetId
JOIN AssetsValueStatusChanges ON AssetValueHistories.SourceModule = @AssetValueAdjustmentValue
AND AssetValueHistories.SourceModuleId = AssetsValueStatusChanges.Id
AND AssetValueHistories.IsCleared = 1
AND AssetValueHistories.IsSchedule = 1
AND AssetValueHistories.IsLessorOwned = 1
JOIN AssetsValueStatusChangeDetails ON AssetsValueStatusChangeDetails.AssetsValueStatusChangeId = AssetsValueStatusChanges.Id
AND AssetValueHistories.AssetId = AssetsValueStatusChangeDetails.AssetId
JOIN LeaseAssets ON AssetsValueStatusChangeDetails.AssetId = LeaseAssets.AssetId
LEFT JOIN #NonTransferAssetSummary ON AssetsValueStatusChangeDetails.AssetId = #NonTransferAssetSummary.AssetId
WHERE
#NonTransferAssetSummary.AssetId IS NULL
GROUP BY AssetsValueStatusChangeDetails.AssetId,LeaseAssets.ETCAdjustmentAmount_Amount,AssetsValueStatusChangeDetails.InstrumentTypeId,AssetsValueStatusChangeDetails.LineofBusinessId,
AssetsValueStatusChangeDetails.CostCenterId,LeaseAssets.NBV_Amount,LeaseAssets.CapitalizedInterimInterest_Amount,LeaseAssets.CapitalizedInterimRent_Amount,LeaseAssets.CapitalizedProgressPayment_Amount,LeaseASsets.CapitalizedSalesTax_Amount
END
IF (EXISTS (SELECT TOP 1* FROM #PIAssetIds) AND @IsRestructure = 0)
BEGIN
INSERT INTO #InventorySummary(AssetId,ETCAdjustmentAmount,InventoryGLTemplateId,InstrumentTypeId,LineofBusinessId,CostCenterId,BranchId,Amount,Type,ExcludeGLSegmentValue)
SELECT
PayableInvoiceAssets.AssetId,
0,
PayableCodes.GLTemplateId,
PayableInvoices.InstrumentTypeId,
PayableInvoices.LineofBusinessId,
PayableInvoices.CostCenterId,
PayableInvoices.BranchId,
(LeaseAssets.NBV_Amount - LeaseAssets.CapitalizedInterimInterest_Amount - LeaseAssets.CapitalizedInterimRent_Amount - LeaseAssets.CapitalizedProgressPayment_Amount - LeaseASsets.CapitalizedSalesTax_Amount),
LeaseFundings.Type,
CASE WHEN #PaidPayables.PaidPIAssetId IS NOT NULL THEN 1 ELSE 0 END
FROM
LeaseFundings
JOIN PayableInvoices ON LeaseFundings.FundingId = PayableInvoices.Id
JOIN PayableCodes ON PayableInvoices.AssetCostPayableCodeId = PayableCodes.Id
JOIN PayableInvoiceOtherCosts ON PayableInvoices.Id = PayableInvoiceOtherCosts.PayableInvoiceId
JOIN PayableInvoiceOtherCostDetails ON PayableInvoiceOtherCosts.Id = PayableInvoiceOtherCostDetails.PayableInvoiceOtherCostId
AND PayableInvoiceOtherCosts.AllocationMethod = @ProgressPaymentCreditValue
JOIN PayableInvoiceAssets ON PayableInvoiceOtherCostDetails.PayableInvoiceAssetId = PayableInvoiceAssets.Id
JOIN LeaseAssets ON PayableInvoiceAssets.AssetId = LeaseAssets.AssetId
AND LeaseAssets.LeaseFinanceId = @LeaseFinanceId
AND LeaseAssets.IsCollateralOnLoan = 1
LEFT JOIN #PaidPayables ON PayableInvoiceAssets.Id = #PaidPayables.PaidPIAssetId
WHERE
LeaseFundings.LeaseFinanceId = @LeaseFinanceId
INSERT INTO #InventorySummary(AssetId,ETCAdjustmentAmount,InventoryGLTemplateId,InstrumentTypeId,LineofBusinessId,CostCenterId,BranchId,Amount,Type,ExcludeGLSegmentValue)
SELECT
LeaseAssets.AssetId as AssetId,
LeaseAssets.ETCAdjustmentAmount_Amount as ETCAdjustmentAmount,
PayableCodes.GLTemplateId as GLTemplateId,
PayableInvoices.InstrumentTypeId as InstrumentTypeId,
PayableInvoices.LineofBusinessId as LineofBusinessId,
PayableInvoices.CostCenterId as CostCenterId,
PayableInvoices.BranchId as BranchId,
(LeaseAssets.NBV_Amount - LeaseAssets.CapitalizedInterimInterest_Amount - LeaseAssets.CapitalizedInterimRent_Amount - LeaseAssets.CapitalizedProgressPayment_Amount - LeaseASsets.CapitalizedSalesTax_Amount) as Amount,
'Origination' as Type,
CASE WHEN #PaidPayables.PaidPIAssetId IS NOT NULL THEN 1 ELSE 0 END as ShouldExcludeSegment
FROM
LeaseFundings
JOIN PayableInvoices ON LeaseFundings.FundingId = PayableInvoices.Id AND LeaseFundings.IsActive = 1
AND LeaseFundings.LeaseFinanceId = @LeaseFinanceId
JOIN LeaseAssets ON PayableInvoices.Id = LeaseAssets.PayableInvoiceId AND LeaseAssets.LeaseFinanceId = @LeaseFinanceId
AND LeaseAssets.CapitalizedForId IS NULL
AND LeaseAssets.IsActive = 1
JOIN PayableInvoiceAssets ON LeaseAssets.AssetId = PayableInvoiceAssets.AssetId
AND PayableInvoiceAssets.PayableInvoiceId = PayableInvoices.Id
AND PayableInvoiceAssets.IsActive = 1
JOIN PayableCodes ON PayableInvoices.AssetCostPayableCodeId = PayableCodes.Id
LEFT JOIN #PaidPayables ON PayableInvoiceAssets.Id = #PaidPayables.PaidPIAssetId
GROUP BY LeaseAssets.AssetId,PayableCodes.GLTemplateId,LeaseAssets.ETCAdjustmentAmount_Amount,LeaseAssets.NBV_Amount,LeaseAssets.CapitalizedInterimInterest_Amount,LeaseAssets.CapitalizedInterimRent_Amount,LeaseASsets.CapitalizedProgressPayment_Amount
,LeaseAssets.CapitalizedSalesTax_Amount,PayableInvoices.InstrumentTypeId,PayableInvoices.LineofBusinessId,PayableInvoices.CostCenterId,PayableInvoices.BranchId,#PaidPayables.PaidPIAssetId
INSERT INTO #NonTransferAssetSummary(AssetId,ETCAdjustmentAmount,InventoryGLTemplateId,InstrumentTypeId,LineofBusinessId,CostCenterId,BranchId,Amount,Type,IsFromPaydown,ExcludeGLSegmentValue)
SELECT
AssetId,
ETCAdjustmentAmount,
InventoryGLTemplateId,
InstrumentTypeId,
LineofBusinessId,
CostCenterId,
BranchId,
SUM(Amount),
Type,
0,
ExcludeGLSegmentValue
FROM
#InventorySummary
GROUP BY AssetId,ETCAdjustmentAmount,InventoryGLTemplateId,Type,InstrumentTypeId,LineofBusinessId,CostCenterId,ExcludeGLSegmentValue,BranchId
END
SELECT
AssetId,
ETCAdjustmentAmount,
InventoryGLTemplateId,
InstrumentTypeId,
LineofBusinessId,
CostCenterId,
BranchId,
Amount,
Type,
IsFromPaydown,
ExcludeGLSegmentValue
FROM
#NonTransferAssetSummary
IF OBJECT_ID('tempdb..#NonTransferAssetIds') IS NOT NULL
DROP TABLE #NonTransferAssetIds;
IF OBJECT_ID('tempdb..#NonTransferAssetSummary') IS NOT NULL
DROP TABLE #NonTransferAssetSummary;
IF OBJECT_ID('tempdb..#InventorySummary') IS NOT NULL
DROP TABLE #InventorySummary;
IF OBJECT_ID('tempdb..#PaidPayables') IS NOT NULL
DROP TABLE #PaidPayables;
IF OBJECT_ID('tempdb..#PIAssetIds') IS NOT NULL
DROP TABLE #PIAssetIds;
END

GO
