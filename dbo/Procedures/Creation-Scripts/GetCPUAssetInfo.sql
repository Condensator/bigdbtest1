SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCPUAssetInfo]
(
@CPUAssetAlias NVARCHAR(MAX),
@IncomeDate DATE,
@AssetMeterTypeId BIGINT
)
AS
BEGIN
SET NOCOUNT ON
SELECT
Id INTO #AssetIds
FROM
Assets
WHERE
Alias IN (
SELECT
Item
FROM
dbo.ConvertCSVToStringTable(@CPUAssetAlias,',')
)
SELECT
Assets.Id AS AssetId,
AssetMeters.MaximumReading AS MeterMaximumReading,
ISNULL(AssetValueHistories.EndBookValue_Amount,0.0) AS LatestAssetValueAmount,
ISNULL(AssetValueHistories.EndBookValue_Currency,'') AS LatestAssetValueCurrency,
ISNULL(LeaseAssetResults.LeaseSequenceNumber,'') AS LeaseSequenceNumber,
LeaseAssetResults.ContractId,
LeaseAssetResults.BillToId,
LeaseAssetResults.RemitToId,
Assets.IsServiceOnly,
Assets.Alias,
Assetmeters.AssetMeterTypeId
FROM
Assets
INNER JOIN #AssetIds
ON Assets.Id = #AssetIds.Id
LEFT JOIN AssetMeters
ON AssetMeters.AssetId = Assets.Id AND
AssetMeters.AssetMeterTypeId = @AssetMeterTypeId
AND AssetMeters.IsActive = 1
LEFT JOIN (
SELECT
MAX(AssetValueHistories.Id) MaxAVHId,
AssetValueHistories.AssetId
FROM
AssetValueHistories
INNER JOIN #AssetIds
ON AssetValueHistories.AssetId = #AssetIds.Id
WHERE
AssetValueHistories.IncomeDate <= @IncomeDate AND
AssetValueHistories.IsSchedule = 1
GROUP BY
AssetValueHistories.AssetId
)
AS MaxAssetValueHistories
ON Assets.Id = MaxAssetValueHistories.AssetId
LEFT JOIN AssetValueHistories
ON AssetValueHistories.AssetId = Assets.Id AND
AssetValueHistories.Id = MaxAssetValueHistories.MaxAVHId
LEFT JOIN (
SELECT
Contracts.SequenceNumber AS LeaseSequenceNumber,
Contracts.RemitToId,
LeaseAssets.BillToId,
LeaseAssets.AssetId,
LeaseFinances.ContractId
FROM
LeaseAssets
INNER JOIN #AssetIds
ON LeaseAssets.AssetId = #AssetIds.Id
INNER JOIN LeaseFinances
ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
INNER JOIN Contracts
ON LeaseFinances.ContractId = Contracts.Id
WHERE
LeaseAssets.IsActive = 1 AND
LeaseFinances.IsCurrent = 1
)
AS LeaseAssetResults
ON Assets.Id = LeaseAssetResults.AssetId
SET NOCOUNT OFF
END

GO
