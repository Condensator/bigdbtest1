SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetPayoffAssetSKUInfoForDistribution]
(
	@LeaseAssetIds LeaseAssetIdType ReadOnly,
	@PayoffEffectiveDate  Date
)
AS
BEGIN
SET NOCOUNT ON

CREATE TABLE #LeaseAssetIds(
	Id BIGINT PRIMARY KEY
)

INSERT INTO #LeaseAssetIds(Id)
SELECT Id FROM @LeaseAssetIds

CREATE TABLE #LeaseAssetSKUDetails(
	AssetSKUId BIGINT PRIMARY KEY,
	AssetId BIGINT NOT NULL,
	LeaseAssetSKUId BIGINT NOT NULL,
	LeaseAssetId BIGINT NOT NULL,
	IsLeaseComponent BIT NOT NULL,
	AssetSKULevelIsLeaseComponent BIT NOT NULL
)

INSERT INTO #LeaseAssetSKUDetails(AssetSKUId, AssetId, LeaseAssetSKUId, LeaseAssetId, IsLeaseComponent, AssetSKULevelIsLeaseComponent)
SELECT
	ASK.Id,
	ASK.AssetId,
	LASK.Id,
	LAI.Id,
	LASK.IsLeaseComponent,
	ASK.IsLeaseComponent
FROM #LeaseAssetIds LAI
JOIN LeaseAssetSKUs LASK ON LAI.Id = LASK.LeaseAssetId AND LASK.IsActive = 1
JOIN AssetSKUs ASK ON LASK.AssetSKUId = ASK.Id AND ASK.IsActive = 1

CREATE TABLE #AssetIds(
	AssetId BIGINT PRIMARY KEY
)

INSERT INTO #AssetIds
SELECT AssetId 
FROM #LeaseAssetSKUDetails
GROUP BY AssetId

CREATE TABLE #ValidAssetValueHistoryIncomeDates(
	AssetId BIGINT,
	IncomeDate Date
)

INSERT INTO #ValidAssetValueHistoryIncomeDates(AssetId, IncomeDate)
SELECT A.AssetId, MAX(AVH.IncomeDate)
FROM AssetValueHistories AVH
INNER JOIN #AssetIds A ON AVH.AssetId = A.AssetId
INNER JOIN SKUValueProportions SVP ON AVH.Id = SVP.AssetValueHistoryId AND SVP.IsActive = 1
WHERE AVH.IncomeDate <= @PayoffEffectiveDate AND AVH.IsSchedule = 1 AND AVH.IsLessorOwned = 1 AND SVP.Value_Amount <> 0 
GROUP BY A.AssetId

CREATE TABLE #ValidAssetValueHistoryIds(
	AssetId BIGINT,
	AssetValueHistoryId BIGINT
)

SELECT V.AssetId, AVH.Id, ROW_NUMBER() OVER (PARTITION BY AVH.AssetId,AVH.IsLeaseComponent ORDER BY AVH.Id DESC) AS [Row]
INTO #TempAssetValueHistoryIds
FROM AssetValueHistories AVH
INNER JOIN SKUValueProportions SVP ON AVH.Id = SVP.AssetValueHistoryId  AND SVP.Value_Amount <> 0 AND SVP.IsActive = 1 
INNER JOIN #ValidAssetValueHistoryIncomeDates V ON AVH.AssetId = V.AssetId
WHERE AVH.IncomeDate = V.IncomeDate AND AVH.IsSchedule = 1 AND AVH.IsLessorOwned = 1

INSERT INTO #ValidAssetValueHistoryIds(AssetId, AssetValueHistoryId)
SELECT AssetId, Id
FROM #TempAssetValueHistoryIds 
WHERE Row = 1

CREATE TABLE #ValidAssetSKUIds(
	AssetSKUId BIGINT PRIMARY KEY
)

INSERT INTO #ValidAssetSKUIds
SELECT AssetSKUId 
FROM #LeaseAssetSKUDetails L
JOIN #ValidAssetValueHistoryIds V ON L.AssetId = V.AssetId
GROUP BY AssetSKUId

;WITH SVPDetails AS(
SELECT A.AssetSKUId, SVP.Value_Amount LatestSKUValueAmount
FROM SKUValueProportions SVP 
INNER JOIN #ValidAssetSKUIds A ON SVP.AssetSKUId = A.AssetSKUId AND SVP.IsActive = 1 
INNER JOIN #ValidAssetValueHistoryIds AVH ON SVP.AssetValueHistoryId = AVH.AssetValueHistoryId
)
SELECT 
	LatestSKUValueAmount,
	LeaseAssetId,
	LeaseAssetSKUId,
	L.AssetSKUId,
	IsLeaseComponent,
	AssetSKULevelIsLeaseComponent
FROM #LeaseAssetSKUDetails L
INNER JOIN SVPDetails S ON L.AssetSKUId = S.AssetSKUId

DROP TABLE #ValidAssetSKUIds
DROP TABLE #LeaseAssetIds
DROP TABLE #LeaseAssetSKUDetails
DROP TABLE #ValidAssetValueHistoryIds
DROP TABLE #ValidAssetValueHistoryIncomeDates
DROP TABLE #TempAssetValueHistoryIds

END

GO
