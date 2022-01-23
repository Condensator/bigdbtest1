SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetAVHInfoForLeaseIncomeRecognition]
(
	 @IncomeRecognitionLeaseIds IncomeRecognitionLeaseIds READONLY
	,@ProcessThroughDate DATETIME 
)
AS
BEGIN
SET NOCOUNT ON;

SELECT
	AllLeaseFinances.Id [LeaseFinanceId], 
	CurrentLeaseFinance.Id [CurrentLeaseFinanceId],
	LeaseAssets.AssetId,	
	LeaseAssets.IsActive,
	LeaseAssets.IsFailedSaleLeaseback,
	LeaseAssets.IsLeaseAsset,
	LeaseAssets.TerminationDate,	
	LeaseAssets.NBV_Amount [NBV],
	LeaseAssets.ETCAdjustmentAmount_Amount [ETCAdjustmentAmount],
	LeaseAssets.BookedResidual_Amount [BookedResidual],
	LeaseAssets.CustomerGuaranteedResidual_Amount [CustomerGuaranteedResidual],
	LeaseAssets.ThirdPartyGuaranteedResidual_Amount [ThirdPartyGuaranteedResidual],
	LeaseAssets.Id [LeaseAssetId]	
INTO #LeaseAssetInfo
FROM @IncomeRecognitionLeaseIds leaseIds
INNER JOIN LeaseFinances CurrentLeaseFinance ON leaseIds.LeaseId = CurrentLeaseFinance.Id
INNER JOIN Contracts ON CurrentLeaseFinance.ContractId = Contracts.Id
INNER JOIN LeaseFinances AllLeaseFinances ON Contracts.Id = AllLeaseFinances.ContractId
INNER JOIN LeaseAssets --WITH (FORCESEEK, INDEX(IX_LeaseFinance)) 
ON CurrentLeaseFinance.Id = LeaseAssets.LeaseFinanceId
WHERE LeaseAssets.IsActive = 1 OR LeaseAssets.TerminationDate IS NOT NULL

SELECT Assets.IsSKU, #LeaseAssetInfo.*
INTO #AssetInfo
FROM #LeaseAssetInfo
JOIN Assets 
ON #LeaseAssetInfo.AssetId = Assets.Id

SELECT 
	AssetValueHistories.Id AS AssetValueHistoryId, #AssetInfo.*
INTO #AssetValueHistorySeekInfo
FROM #AssetInfo
INNER JOIN AssetValueHistories
ON #AssetInfo.AssetId = AssetValueHistories.AssetId
	AND #AssetInfo.LeaseFinanceId = AssetValueHistories.SourceModuleId 
	AND IncomeDate <= @ProcessThroughDate
	AND IsLessorOwned = 1 
	AND IsAccounted = 1 
	AND AssetValueHistories.AdjustmentEntry = 0
	AND SourceModule IN ('FixedTermDepreciation', 'OTPDepreciation', 'ResidualReclass', 'ResidualRecapture')

SELECT 
	#AssetValueHistorySeekInfo.CurrentLeaseFinanceId [LeaseFinanceId],
	#AssetValueHistorySeekInfo.AssetId,
	#AssetValueHistorySeekInfo.IsActive,
	CASE 
		WHEN SourceModule = 'FixedTermDepreciation'
			THEN CONVERT(BIT, #AssetValueHistorySeekInfo.IsLeaseAsset)
		WHEN #AssetValueHistorySeekInfo.IsFailedSaleLeaseback = 1
			THEN CONVERT(BIT, 0)
		ELSE 
			CONVERT(BIT, AssetValueHistories.IsLeaseComponent)
	END AS [IsLeaseAsset],
	#AssetValueHistorySeekInfo.TerminationDate,
	#AssetValueHistorySeekInfo.NBV,
	#AssetValueHistorySeekInfo.ETCAdjustmentAmount,
	#AssetValueHistorySeekInfo.BookedResidual,
	#AssetValueHistorySeekInfo.CustomerGuaranteedResidual,
	#AssetValueHistorySeekInfo.ThirdPartyGuaranteedResidual,
	AssetValueHistories.IncomeDate,
	AssetValueHistories.SourceModule,
	AssetValueHistories.Value_Amount [Value],
	AssetValueHistories.NetValue_Amount [NetValue],
	AssetValueHistories.Id [AssetValueHistoryId],
	AssetValueHistories.IsCleared,
	#AssetValueHistorySeekInfo.IsSKU [HasSku],
	#AssetValueHistorySeekInfo.LeaseAssetId,
	AssetValueHistories.IsLeaseComponent,
	AssetValueHistories.GLJournalId
FROM AssetValueHistories
JOIN #AssetValueHistorySeekInfo ON AssetValueHistories.Id = #AssetValueHistorySeekInfo.AssetValueHistoryId
WHERE GLJournalId IS NULL

DROP TABLE #LeaseAssetInfo
DROP TABLE #AssetValueHistorySeekInfo
DROP TABLE #AssetInfo

END

GO
