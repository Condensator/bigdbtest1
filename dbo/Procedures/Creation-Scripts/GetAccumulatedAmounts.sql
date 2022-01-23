SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetAccumulatedAmounts]
(
@AssetIds AssetIdList READONLY,
@CommencementDate DATETIME,
@IsForTransferAssets BIT,
@InventoryBookDepreciationValue NVARCHAR(26) = NULL,
@AssetImpairmentValue NVARCHAR(20) = NULL,
@ContractId BIGINT = NULL,
@LeaseFinanceId BIGINT = NULL,
@PayoffActivatedStatusValue NVARCHAR(9) = nULL,
@LeaseBookingCommencedStatusValue NVARCHAR(9)= NULL,
@LeaseBookingFullyPaidOffStatusValue NVARCHAR(12) = NULL,
@FixedTermDepreciationValue NVARCHAR(21) = NULL,
@OTPDepreciationValue NVARCHAR(15) = NULL,
@ResidualRecaptureValue NVARCHAR(17) = NULL,
@NBVImpairmentValue NVARCHAR(14) = NULL,
@InactiveStatusValue NVARCHAR(8) = NULL,
@AssetBookValueAdjustmentValue NVARCHAR(21) = NULL
)
AS
CREATE TABLE #AccumulatedAmountInfo
(
Type NVARCHAR(50) NOT NULL,
AssetId BIGINT NOT NULL,
GLTemplateId BIGINT NOT NULL,
InstrumentTypeId BIGINT NOT NULL,
LineofBusinessId BIGINT NOT NULL,
CostCenterId BIGINT NOT NULL,
Amount DECIMAL(16,2) NOT NULL,
ClearedTillDate DATE
)
SELECT * INTO #SelectedAssets FROM @AssetIds
ALTER TABLE #SelectedAssets ADD PRIMARY KEY (AssetId)
BEGIN
SELECT
AssetGLDetails.Id as AssetId,
AssetGLDetails.InstrumentTypeId,
AssetGLDetails.LineofBusinessId,
AssetGLDetails.CostCenterId,
MAX(AssetValueHistories.Id) AS MaxAssetValueHistoryId
INTO #AssetValueSummary
FROM
AssetValueHistories
JOIN #SelectedAssets ON AssetValueHistories.AssetId = #SelectedAssets.AssetId AND AssetValueHistories.IsAccounted = 1
AND AssetValueHistories.IsCleared = 1  AND AssetValueHistories.IsLessorOwned = 1
JOIN AssetGLDetails ON AssetGLDetails.Id = #SelectedAssets.AssetId
GROUP BY AssetGLDetails.Id,AssetGLDetails.InstrumentTypeId,AssetGLDetails.LineofBusinessId,AssetGLDetails.CostCenterId
INSERT INTO #AccumulatedAmountInfo(Type,AssetId,GLTemplateId,InstrumentTypeId,LineofBusinessId,CostCenterId,Amount,ClearedTillDate)
SELECT
@InventoryBookDepreciationValue,
AssetValueHistories.AssetId,
BookDepreciations.GLTemplateId,
#AssetValueSummary.InstrumentTypeId,
#AssetValueSummary.LineofBusinessId,
#AssetValueSummary.CostCenterId,
SUM(AssetValueHistories.Value_Amount) * (-1) AS Amount,
MAX(AssetValueHistories.IncomeDate) as ClearedTillDate
FROM
#AssetValueSummary
JOIN AssetValueHistories ON #AssetValueSummary.AssetId = AssetValueHistories.AssetId
AND AssetValueHistories.IsAccounted = 1  AND AssetValueHistories.IsLessorOwned = 1
AND AssetValueHistories.Id > #AssetValueSummary.MaxAssetValueHistoryId
AND AssetValueHistories.IncomeDate < @CommencementDate
JOIN BookDepreciations ON AssetValueHistories.SourceModuleId = BookDepreciations.Id
AND AssetValueHistories.SourceModule = @InventoryBookDepreciationValue
GROUP BY AssetValueHistories.AssetId,BookDepreciations.GLTemplateId,#AssetValueSummary.InstrumentTypeId,#AssetValueSummary.LineofBusinessId,#AssetValueSummary.CostCenterId
INSERT INTO #AccumulatedAmountInfo(Type,AssetId,GLTemplateId,InstrumentTypeId,LineofBusinessId,CostCenterId,Amount,ClearedTillDate)
SELECT
@AssetImpairmentValue,
AssetValueHistories.AssetId,
AssetsValueStatusChangeDetails.GLTemplateId,
#AssetValueSummary.InstrumentTypeId,
#AssetValueSummary.LineofBusinessId,
#AssetValueSummary.CostCenterId,
SUM(AssetValueHistories.Value_Amount) * (-1) AS Amount,
MAX(AssetValueHistories.IncomeDate) as ClearedTillDate
FROM
#AssetValueSummary
JOIN AssetValueHistories ON #AssetValueSummary.AssetId = AssetValueHistories.AssetId
AND AssetValueHistories.IsAccounted = 1
AND AssetValueHistories.IsLessorOwned = 1
AND AssetValueHistories.Id > #AssetValueSummary.MaxAssetValueHistoryId
AND AssetValueHistories.IncomeDate < @CommencementDate
JOIN AssetsValueStatusChanges ON AssetValueHistories.SourceModuleId = AssetsValueStatusChanges.Id
AND AssetValueHistories.SourceModule = @AssetImpairmentValue
JOIN AssetsValueStatusChangeDetails ON AssetsValueStatusChanges.Id = AssetsValueStatusChangeDetails.AssetsValueStatusChangeId
AND AssetsValueStatusChangeDetails.AssetId = AssetValueHistories.AssetId
GROUP BY AssetValueHistories.AssetId,AssetsValueStatusChangeDetails.GLTemplateId,#AssetValueSummary.InstrumentTypeId,#AssetValueSummary.LineofBusinessId,#AssetValueSummary.CostCenterId
If(@IsForTransferAssets = 1)
BEGIN
SELECT
AssetGLDetails.Id as AssetId,
AssetGLDetails.InstrumentTypeId,
AssetGLDetails.LineofBusinessId,
AssetGLDetails.CostCenterId,
MAX(LeaseFinances.Id) as MaxLeaseFinanceId
INTO #PayoffLeaseSummary
FROM
LeaseAssets
JOIN #SelectedAssets ON LeaseAssets.AssetId = #SelectedAssets.AssetId
JOIN PayoffAssets ON LeaseAssets.Id = PayoffAssets.LeaseAssetId
JOIN Payoffs ON PayoffAssets.PayoffId = Payoffs.Id
JOIN LeaseFinances ON Payoffs.LeaseFinanceId = LeaseFinances.Id
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
JOIN AssetGLDetails ON #SelectedAssets.AssetId = AssetGLDetails.Id
WHERE
PayoffAssets.IsActive = 1
AND Payoffs.Status = @PayoffActivatedStatusValue
AND Contracts.Id <> @ContractId
AND LeaseFinances.BookingStatus IN (@LeaseBookingCommencedStatusValue,@LeaseBookingFullyPaidOffStatusValue)
GROUP BY AssetGLDetails.Id,AssetGLDetails.InstrumentTypeId,AssetGLDetails.LineofBusinessId,AssetGLDetails.CostCenterId
INSERT INTO #AccumulatedAmountInfo(Type,AssetId,GLTemplateId,InstrumentTypeId,LineofBusinessId,CostCenterId,Amount,ClearedTillDate)
SELECT
@FixedTermDepreciationValue,
AssetValueHistories.AssetId,
Payoffs.PayoffGLTemplateId,
#PayoffLeaseSummary.InstrumentTypeId,
#PayoffLeaseSummary.LineofBusinessId,
#PayoffLeaseSummary.CostCenterId,
SUM(AssetValueHistories.Value_Amount) * (-1) AS Amount,
MAX(AssetValueHistories.IncomeDate) as ClearedTillDate
FROM
#AssetValueSummary
JOIN AssetValueHistories ON #AssetValueSummary.AssetId = AssetValueHistories.AssetId
AND AssetValueHistories.IsAccounted = 1
AND AssetValueHistories.IsLessorOwned = 1
AND AssetValueHistories.Id > #AssetValueSummary.MaxAssetValueHistoryId
AND AssetValueHistories.IncomeDate < @CommencementDate
AND AssetValueHistories.SourceModule IN (@FixedTermDepreciationValue,@OTPDepreciationValue,@ResidualRecaptureValue)
JOIN #PayoffLeaseSummary ON AssetValueHistories.AssetId = #PayoffLeaseSummary.AssetId
JOIN LeaseFinanceDetails ON AssetValueHistories.SourceModuleId = LeaseFinanceDetails.Id
AND LeaseFinanceDetails.Id = #PayoffLeaseSummary.MaxLeaseFinanceId
JOIN LeaseAssets ON AssetValueHistories.AssetId = LeaseAssets.AssetId
JOIN PayoffAssets ON LeaseAssets.Id = PayoffAssets.LeaseAssetId AND PayoffAssets.IsActive = 1
JOIN Payoffs ON PayoffAssets.PayoffId = Payoffs.Id AND Payoffs.Status = @PayoffActivatedStatusValue
GROUP BY AssetValueHistories.AssetId,Payoffs.PayoffGLTemplateId,#PayoffLeaseSummary.InstrumentTypeId,#PayoffLeaseSummary.LineofBusinessId,#PayoffLeaseSummary.CostCenterId
INSERT INTO #AccumulatedAmountInfo(Type,AssetId,GLTemplateId,InstrumentTypeId,LineofBusinessId,CostCenterId,Amount,ClearedTillDate)
SELECT
@NBVImpairmentValue,
AssetValueHistories.AssetId,
Payoffs.PayoffGLTemplateId,
#PayoffLeaseSummary.InstrumentTypeId,
#PayoffLeaseSummary.LineofBusinessId,
#PayoffLeaseSummary.CostCenterId,
SUM(AssetValueHistories.Value_Amount) * (-1) AS Amount,
MAX(AssetValueHistories.IncomeDate) as ClearedTillDate
FROM
#AssetValueSummary
JOIN AssetValueHistories ON #AssetValueSummary.AssetId = AssetValueHistories.AssetId
AND AssetValueHistories.IsAccounted = 1
AND AssetValueHistories.IsLessorOwned = 1
AND AssetValueHistories.Id > #AssetValueSummary.MaxAssetValueHistoryId
AND AssetValueHistories.IncomeDate < @CommencementDate
AND AssetValueHistories.SourceModule IN (@NBVImpairmentValue)
JOIN #PayoffLeaseSummary ON AssetValueHistories.AssetId = #PayoffLeaseSummary.AssetId
JOIN Assets ON #PayoffLeaseSummary.AssetId = Assets.Id
JOIN LeaseAssets ON Assets.Id = LeaseAssets.AssetId
JOIN PayoffAssets ON LeaseAssets.Id = PayoffAssets.LeaseAssetId AND PayoffAssets.IsActive = 1
JOIN Payoffs ON PayoffAssets.PayoffId = Payoffs.Id AND Payoffs.Status = @PayoffActivatedStatusValue
GROUP BY AssetValueHistories.AssetId,Payoffs.PayoffGLTemplateId,#PayoffLeaseSummary.InstrumentTypeId,#PayoffLeaseSummary.LineofBusinessId,#PayoffLeaseSummary.CostCenterId
SELECT
PayableInvoiceAssets.AssetId,
GLTemplateId
INTO #PIAssetMap
FROM
LeaseAssets
JOIN PayableInvoiceAssets ON LeaseAssets.AssetId = PayableInvoiceAssets.AssetId
JOIN PayableInvoices ON PayableInvoiceAssets.PayableInvoiceId = PayableInvoices.Id
JOIN PayableCodes ON PayableInvoices.AssetCostPayableCodeId = PayableCodes.Id
WHERE
LeaseAssets.LeaseFinanceId = @LeaseFinanceId
AND LeaseAssets.IsActive = 1
AND LeaseAssets.IsTransferAsset = 1
AND PayableInvoiceAssets.IsActive =1
AND PayableInvoices.Status <> @InactiveStatusValue
SELECT
AssetValueHistories.AssetId,
AssetsValueStatusChangeDetails.GLTemplateId
INTO #AVSCMap
FROM
LeaseAssets
JOIN AssetValueHistories ON LeaseAssets.AssetId = AssetValueHistories.AssetId
AND LeaseAssets.IsActive = 1
AND LeaseAssets.IsTransferAsset =1
AND LeaseAssets.LeaseFinanceId = @LeaseFinanceId
JOIN AssetsValueStatusChanges ON AssetValueHistories.SourceModule = @AssetBookValueAdjustmentValue
AND AssetValueHistories.SourceModuleId = AssetsValueStatusChanges.Id
AND AssetValueHistories.IsCleared = 1
AND AssetValueHistories.IsLessorOwned = 1
JOIN AssetsValueStatusChangeDetails ON AssetsValueStatusChangeDetails.AssetsValueStatusChangeId = AssetsValueStatusChanges.Id
AND AssetsValueStatusChangeDetails.AssetId= AssetValueHistories.AssetId
SELECT
CASE WHEN Payoffs.IsPaidOffInInstallPhase = 1
THEN
CASE WHEN #PIAssetMap.AssetId IS NOT NULL
THEN #PIAssetMap.GLTemplateId
ELSE #AVSCMap.GLTemplateId
END
ELSE
Payoffs.PayoffGLTemplateId
END as PayoffGLTemplateId,
#PayoffLeaseSummary.AssetId,
#PayoffLeaseSummary.InstrumentTypeId,
#PayoffLeaseSummary.LineofBusinessId,
#PayoffLeaseSummary.CostCenterId
INTO #TransferAssetSummary
FROM
PayoffAssets
JOIN Payoffs ON PayoffAssets.PayoffId = Payoffs.Id
AND PayoffAssets.IsActive = 1
AND Payoffs.Status = @PayoffActivatedStatusValue
JOIN LeaseAssets ON PayoffAssets.LeaseAssetId = LeaseAssets.Id
JOIN #SelectedAssets ON LeaseAssets.AssetId = #SelectedAssets.AssetId
JOIN LeaseFinanceDetails ON Payoffs.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN #PayoffLeaseSummary ON #SelectedAssets.AssetId = #PayoffLeaseSummary.AssetId
AND LeaseFinanceDetails.Id = #PayoffLeaseSummary.MaxLeaseFinanceId
LEFT JOIN #AVSCMap ON #PayoffLeaseSummary.AssetId = #AVSCMap.AssetId
LEFT JOIN #PIAssetMap ON #PayoffLeaseSummary.AssetId = #PIAssetMap.AssetId
WHERE
(#AVSCMap.AssetId IS NOT NULL OR #PIAssetMap.AssetId IS NOT NULL)
END
SELECT
*
FROM
#AccumulatedAmountInfo
IF(@IsForTransferAssets = 1)
BEGIN
SELECT
*
FROM
#TransferAssetSummary
END
IF OBJECT_ID('tempdb..#SelectedAssets') IS NOT NULL
DROP TABLE #SelectedAssets;
IF OBJECT_ID('tempdb..#AssetValueSummary') IS NOT NULL
DROP TABLE #AssetValueSummary;
IF OBJECT_ID('tempdb..#AccumulatedAmountInfo') IS NOT NULL
DROP TABLE #AccumulatedAmountInfo;
IF OBJECT_ID('tempdb..#PIAssetMap') IS NOT NULL
DROP TABLE #PIAssetMap;
IF OBJECT_ID('tempdb..#AVSCMap') IS NOT NULL
DROP TABLE #AVSCMap;
IF OBJECT_ID('tempdb..#PayoffLeaseSummary') IS NOT NULL
DROP TABLE #PayoffLeaseSummary;
IF OBJECT_ID('tempdb..#TransferAssetSummary') IS NOT NULL
DROP TABLE #TransferAssetSummary;
END

GO
