SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetAssetInfoForCPUSchedule]
(
@AssetIds NVARCHAR(MAX),
@MeterTypeId  BIGINT ,
@CommencementDate DATETIME
)
AS
SET NOCOUNT ON;
BEGIN
SELECT * INTO #SelectedAssetIds FROM STRING_SPLIT(@AssetIds,',')
;WITH SelectedAssetDetails AS
(
SELECT
Assets.Id
,AssetMeters.MaximumReading
,Contracts.SequenceNumber
,Contracts.Id 'ContractId'
,Contracts.RemitToId
,ISNULL(AssetValueHistories.EndBookValue_Amount, 0) as EndBookValue_Amount
,AssetValueHistories.EndBookValue_Currency
,LeaseAssets.BillToId
,ROW_NUMBER() OVER (PARTITION BY Assets.Id ORDER BY AssetValueHistories.Id DESC) [FirstRecord]
FROM Assets
INNER JOIN #SelectedAssetIds ON Assets.Id=#SelectedAssetIds.Value
INNER JOIN AssetMeters ON Assets.Id=AssetMeters.AssetId AND  AssetMeters.AssetMeterTypeId=@MeterTypeId
LEFT JOIN LeaseAssets ON Assets.Id=LeaseAssets.AssetId
LEFT JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId=LeaseFinances.Id
LEFT JOIN Contracts ON LeaseFinances.ContractId=Contracts.Id
LEFT JOIN AssetValueHistories ON Assets.Id=AssetValueHistories.AssetId AND AssetValueHistories.IncomeDate<=@CommencementDate
AND AssetValueHistories.IsSchedule=1
WHERE   AssetMeters.IsActive=1
)
SELECT
Id [AssetId]
,EndBookValue_Amount [LatestAssetValueAmount]
,EndBookValue_Currency [LatestAssetValueCurrency]
,SequenceNumber [LeaseSequenceNumber]
,MaximumReading [MeterMaximumReading]
,ContractId
,RemitToId
,BillToId
FROM SelectedAssetDetails WHERE
(SequenceNumber IS NULL) OR
(SequenceNumber IS NOT NULL AND FirstRecord=1)
IF OBJECT_ID('tempdb..#SelectedAssetIds') IS NOT NULL
DROP TABLE #SelectedAssetIds;
END

GO
