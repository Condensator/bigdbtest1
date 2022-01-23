SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AssetStatusChangeFromLease]
(
@LeaseFinanceId BIGINT,
@AssetHistoryReasonStatusChange NVARCHAR(15),
@SourceModule NVARCHAR(25),
@CommencementDate DATETIME = NULL,
@ContractId BIGINT,
@AssetStatusLeased NVARCHAR(20),
@AssetStatusInventory NVARCHAR(20),
@AssetStatusInvestorLeased NVARCHAR(20),
@AssetStatusInvestor NVARCHAR(20),
@AssetStatusScrap NVARCHAR(20),
@AssetStatusCollateralOnLoan NVARCHAR(20),
@DummyFinancialType NVARCHAR(20),
@AssetFinancialTypeDeposit NVARCHAR(20),
@AssetFinancialTypeNegativeDeposit NVARCHAR(20),
@IsSyndicated BIT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@IsCommenceStep BIT,
@ConsiderOnlyInactiveAssets BIT,
@ProcessOnlyNewlyAddedAssets BIT -- Added for Rebook
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
CREATE TABLE #AssetDetails
(
AssetId BIGINT,
AssetStatus NVARCHAR(20),
LeaseAssetIsActive BIT,
LeaseAssetCapitalizedForId BIGINT,
AsOfDate DATE,
IsCollateralOnLoan BIT,
IsStatusChanged BIT,
FinancialType NVARCHAR(20),
IsOffLease BIT,
IsInactivePayableInvoiceAsset BIT
)

IF(@IsCommenceStep = 1)
BEGIN
UPDATE Assets SET IsOnCommencedLease = LeaseAssets.IsActive
FROM Assets
INNER JOIN LeaseAssets ON Assets.Id = LeaseAssets.AssetId
WHERE LeaseAssets.LeaseFinanceId = @LeaseFinanceId
END
SELECT
DISTINCT Asset.Id AssetId
INTO #InactivatedPIAsset
FROM Assets Asset
INNER JOIN LeaseAssets LeaseAsset ON Asset.Id = LeaseAsset.AssetId
INNER JOIN PayableInvoiceAssets PayableInvoiceAsset ON LeaseAsset.PayableInvoiceId = PayableInvoiceAsset.PayableInvoiceId AND PayableInvoiceAsset.AssetId = LeaseAsset.AssetId
INNER JOIN PayableInvoices PayableInvoice	ON PayableInvoice.Id = PayableInvoiceAsset.PayableInvoiceId AND PayableInvoice.ParentPayableInvoiceId IS NULL
WHERE LeaseAsset.LeaseFinanceId = @LeaseFinanceId
AND (@ProcessOnlyNewlyAddedAssets = 0 OR LeaseAsset.IsNewlyAdded = 1)
AND LeaseAsset.IsActive = 0
AND PayableInvoiceAsset.IsActive=0
AND PayableInvoice.Status='InActive'
AND Asset.Status IN (@AssetStatusInventory,@AssetStatusLeased, @AssetStatusInvestorLeased)
SELECT
AssetHistories.Id,
AssetHistories.AssetId,
AssetHistories.Status,
AssetHistories.AsOfDate
INTO #AssetHistoryTemp
FROM
AssetHistories
JOIN LeaseAssets ON AssetHistories.AssetId = LeaseAssets.AssetId
WHERE
LeaseAssets.LeaseFinanceId = @LeaseFinanceId
AND AssetHistories.Status IN (@AssetStatusLeased,@AssetStatusInvestorLeased,@AssetStatusInventory)
INSERT INTO #AssetDetails
SELECT
Asset.Id
,Asset.Status
,LeaseAsset.IsActive
,LeaseAsset.CapitalizedForId
,CASE WHEN (LeaseAsset.IsActive = 1 AND LeaseAsset.InterimInterestStartDate IS NOT NULL) THEN LeaseAsset.InterimInterestStartDate
WHEN (LeaseAsset.IsActive = 1 AND LeaseAsset.InterimInterestStartDate IS NULL AND LeaseAsset.InterimRentStartDate IS NOT NULL) THEN LeaseAsset.InterimRentStartDate
WHEN (LeaseAsset.IsActive = 1 AND LeaseAsset.InterimInterestStartDate IS NULL AND LeaseAsset.InterimRentStartDate IS NULL AND (LeaseAsset.ValueAsOfDate IS NULL OR LeaseAsset.ValueAsOfDate <= @CommencementDate)) THEN @CommencementDate
WHEN (LeaseAsset.IsActive = 1 AND LeaseAsset.InterimInterestStartDate IS NULL AND LeaseAsset.InterimRentStartDate IS NULL AND LeaseAsset.ValueAsOfDate > @CommencementDate) THEN LeaseAsset.ValueAsOfDate
WHEN (LeaseAsset.IsActive = 0) THEN (SELECT TOP 1 AsOfDate FROM #AssetHistoryTemp WHERE AssetId = Asset.Id AND Status IN(@AssetStatusLeased,@AssetStatusInvestorLeased) ORDER BY Id DESC) -- This can be further enhanced by doing left join with #AssetHistoryTemp
END
,LeaseAsset.IsCollateralOnLoan
,0
,Asset.FinancialType
,Asset.IsOffLease
,CASE WHEN #InactivatedPIAsset.AssetId IS NULL THEN 0 ELSE 1 END
FROM Assets Asset
INNER JOIN LeaseAssets LeaseAsset ON Asset.Id = LeaseAsset.AssetId
LEFT JOIN #InactivatedPIAsset ON LeaseAsset.AssetId = #InactivatedPIAsset.AssetId
WHERE LeaseAsset.LeaseFinanceId = @LeaseFinanceId
AND (@ProcessOnlyNewlyAddedAssets = 0 OR LeaseAsset.IsNewlyAdded = 1)
AND
(	 (@ConsiderOnlyInactiveAssets = 0 AND LeaseAsset.IsActive = 1 AND Asset.Status IN (@AssetStatusInventory, @AssetStatusInvestor, @AssetStatusCollateralOnLoan))
OR
(LeaseAsset.IsActive = 0 AND Asset.Status IN (@AssetStatusLeased, @AssetStatusInvestorLeased))
OR
(LeaseAsset.IsActive = 0 AND LeaseAsset.CapitalizedForId IS NOT NULL)
)

SELECT Lease.ContractId 
INTO #ContractTemp
FROM LeaseFinances Lease 
WHERE Lease.Id = @LeaseFinanceId

SELECT #AssetDetails.AssetId 
INTO #AssetsAssociatedWithOtherActiveLeases 
FROM #AssetDetails 
JOIN LeaseAssets LeaseAsset ON #AssetDetails.AssetId = LeaseAsset.AssetId
JOIN LeaseFinances Lease ON LeaseAsset.LeaseFinanceId = Lease.Id AND Lease.IsCurrent = 1 AND LeaseAsset.IsActive = 1
JOIN #ContractTemp CT ON Lease.ContractId != CT.ContractId 

DELETE FROM #AssetDetails  
WHERE AssetId IN (SELECT AssetId FROM #AssetsAssociatedWithOtherActiveLeases)



INSERT INTO #AssetDetails
SELECT
Asset.Id
,Asset.Status
,LeaseAsset.IsActive
,LeaseAsset.CapitalizedForId
,(SELECT TOP 1 AsOfDate FROM #AssetHistoryTemp WHERE AssetId = Asset.Id AND Status IN(@AssetStatusLeased,@AssetStatusInvestorLeased,@AssetStatusInventory) ORDER BY Id DESC)
,LeaseAsset.IsCollateralOnLoan
,0
,Asset.FinancialType
,Asset.IsOffLease
,1
FROM Assets Asset
INNER JOIN LeaseAssets LeaseAsset ON Asset.Id = LeaseAsset.AssetId
INNER JOIN #InactivatedPIAsset ON LeaseAsset.AssetId = #InactivatedPIAsset.AssetId
WHERE LeaseAsset.LeaseFinanceId = @LeaseFinanceId
AND (@ProcessOnlyNewlyAddedAssets = 0 OR LeaseAsset.IsNewlyAdded = 1)
AND LeaseAsset.IsActive = 0 AND LeaseAsset.PayableInvoiceId IS NOT NULL AND Asset.Status IN (@AssetStatusInventory)
IF (@IsSyndicated = 0)
BEGIN
UPDATE #AssetDetails SET AssetStatus = @AssetStatusLeased, IsStatusChanged = 1, IsOffLease = 0
WHERE LeaseAssetIsActive = 1 AND AssetStatus IN (@AssetStatusInventory, @AssetStatusCollateralOnLoan)
END
ELSE
BEGIN
UPDATE #AssetDetails SET AssetStatus = @AssetStatusInvestorLeased, IsStatusChanged = 1,IsOffLease=0
WHERE LeaseAssetIsActive = 1 AND AssetStatus IN (@AssetStatusInvestor, @AssetStatusInventory, @AssetStatusCollateralOnLoan)
END
UPDATE #AssetDetails
SET AssetStatus = CASE WHEN (LeaseAssetCapitalizedForId IS NOT NULL OR FinancialType IN (@AssetFinancialTypeDeposit,@AssetFinancialTypeNegativeDeposit)) THEN @AssetStatusScrap
WHEN AssetStatus = @AssetStatusLeased AND IsCollateralOnLoan = 0 THEN @AssetStatusInventory
WHEN AssetStatus = @AssetStatusInvestorLeased AND IsCollateralOnLoan = 0 THEN @AssetStatusInvestor
WHEN IsCollateralOnLoan = 1 THEN @AssetStatusCollateralOnLoan
END,
IsStatusChanged = 1,
IsOffLease = 1
WHERE LeaseAssetIsActive = 0
AND AssetStatus NOT IN (@AssetStatusInventory,@AssetStatusInvestor,@AssetStatusCollateralOnLoan);
UPDATE Assets SET Status = #AssetDetails.AssetStatus, UpdatedTime = @CreatedTime, UpdatedById = @CreatedById, IsOffLease = #AssetDetails.IsOffLease
FROM Assets
INNER JOIN #AssetDetails ON Assets.Id = #AssetDetails.AssetId
WHERE IsStatusChanged = 1 AND (IsCollateralOnLoan = 0 OR LeaseAssetIsActive = 1)
UPDATE Assets SET Status = #AssetDetails.AssetStatus, FinancialType= @DummyFinancialType, UpdatedTime = @CreatedTime, UpdatedById = @CreatedById,IsOffLease=#AssetDetails.IsOffLease
FROM Assets
INNER JOIN #AssetDetails ON Assets.Id = #AssetDetails.AssetId
WHERE #AssetDetails.IsStatusChanged = 1 AND #AssetDetails.IsCollateralOnLoan = 1 AND #AssetDetails.LeaseAssetIsActive = 0


INSERT INTO AssetHistories
([Reason]
,[AsOfDate]
,[AcquisitionDate]
,[Status]
,[FinancialType]
,[SourceModule]
,[SourceModuleId]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
,[ContractId]
,[AssetId]
,[IsReversed]
,[PropertyTaxReportCodeId])
SELECT
@AssetHistoryReasonStatusChange
,#AssetDetails.AsOfDate
,Assets.AcquisitionDate
,Assets.Status
,Assets.FinancialType
,@SourceModule
,@ContractId
,@CreatedById
,@CreatedTime
,NULL
,NULL
,Assets.CustomerId
,Assets.ParentAssetId
,Assets.LegalEntityId
,@ContractId
,Assets.Id
,0
,Assets.PropertyTaxReportCodeId
FROM Assets
INNER JOIN #AssetDetails ON Assets.Id = #AssetDetails.AssetId
WHERE #AssetDetails.IsStatusChanged = 1
SELECT
AssetHistory.Id, AssetDetail.AsOfDate, ROW_NUMBER() OVER (PARTITION BY AssetHistory.AssetId ORDER BY AssetHistory.Id DESC) AS RowNumber INTO #AssetHistories
FROM #AssetHistoryTemp AssetHistory
JOIN #AssetDetails AssetDetail ON AssetHistory.AssetId = AssetDetail.AssetId
WHERE IsStatusChanged= 0
AND Status IN(@AssetStatusLeased,@AssetStatusInvestorLeased)
AND AssetHistory.AsOfDate != AssetDetail.AsOfDate
UPDATE AssetHistory SET AsOfDate = AssetHistoryId.AsOfDate, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM AssetHistories AssetHistory
JOIN #AssetHistories AssetHistoryId ON AssetHistory.Id = AssetHistoryId.Id
WHERE RowNumber = 1
DROP TABLE #AssetDetails
DROP TABLE #AssetHistories
DROP TABLE #AssetHistoryTemp
DROP TABLE #InactivatedPIAsset
DROP TABLE #ContractTemp
DROP TABLE #AssetsAssociatedWithOtherActiveLeases
SET NOCOUNT OFF
END

GO
