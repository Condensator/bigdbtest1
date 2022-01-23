SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateGLJournalIdForETCAssetValueHistories]
(
@ContractId BIGINT,
@LeaseFinanceId BIGINT,
@SourceModule NVARCHAR(25),
@IsRebook BIT,
@IsReverse BIT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #ETCAssetDetails
(
AssetId BIGINT
,GLJournalId BIGINT
,SourceId BIGINT
)
--IF(@IsReverse = 1)
--BEGIN
--INSERT INTO #ETCAssetDetails
--SELECT
--	[LA].AssetId
--	,[GLJ].Id
--	,[PBI].Id
--	FROM LeaseBlendedItems [LBI]
--	INNER JOIN BlendedItems [BI] ON [LBI].BlendedItemId = [BI].Id
--	INNER JOIN BlendedItems [PBI] ON [BI].ParentBlendedItemId = [PBI].Id
--	INNER JOIN BlendedItemAssets [BIA] ON [PBI].Id = [BIA].BlendedItemId
--	INNER JOIN LeaseAssets [LA] ON [BIA].LeaseAssetId = [LA].Id
--	INNER JOIN BlendedItemDetails [BID] ON [PBI].Id = [BID].BlendedItemId
--	INNER JOIN GLJournalDetails [GLJD] ON [GLJD].EntityType = 'Contract' AND [GLJD].EntityId = @ContractId AND [GLJD].SourceId = [BID].Id
--	INNER JOIN GLJournals [GLJ] ON [GLJD].GLJournalId = [GLJ].Id
--	WHERE [LBI].LeaseFinanceId = @LeaseFinanceId AND [GLJ].IsReversalEntry = 1 AND [BI].IsNewlyAdded = 0 AND ([BI].IsActive = 0 OR [LBI].Revise = 1)
--	GROUP BY [LA].AssetId,[GLJ].Id,[PBI].Id
--END
IF(@IsRebook = 1)
BEGIN
INSERT INTO #ETCAssetDetails
SELECT
LeaseAssets.AssetId
,GLJournals.Id
,BlendedItems.Id
FROM LeaseBlendedItems
INNER JOIN BlendedItems ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id AND BlendedItems.IsActive=1
INNER JOIN BlendedItemAssets ON BlendedItems.Id = BlendedItemAssets.BlendedItemId AND BlendedItemAssets.IsActive=1
INNER JOIN LeaseAssets ON BlendedItemAssets.LeaseAssetId = LeaseAssets.Id
INNER JOIN BlendedItemDetails ON BlendedItems.Id = BlendedItemDetails.BlendedItemId AND BlendedItemDetails.IsActive=1
INNER JOIN GLJournalDetails ON GLJournalDetails.EntityType = 'Contract' AND GLJournalDetails.EntityId = @ContractId AND GLJournalDetails.SourceId = BlendedItemDetails.Id
INNER JOIN GLJournals ON GLJournalDetails.GLJournalId = GLJournals.Id
WHERE LeaseBlendedItems.LeaseFinanceId = @LeaseFinanceId AND GLJournals.IsReversalEntry = 0 AND (BlendedItems.IsNewlyAdded = 1 OR LeaseBlendedItems.Revise = 1)
GROUP BY LeaseAssets.AssetId,GLJournals.Id,BlendedItems.Id
END
ELSE
BEGIN
INSERT INTO #ETCAssetDetails
SELECT
LeaseAssets.AssetId
,GLJournals.Id
,BlendedItems.Id
FROM LeaseBlendedItems
INNER JOIN BlendedItems ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id AND BlendedItems.IsActive=1
INNER JOIN BlendedItemAssets ON BlendedItems.Id = BlendedItemAssets.BlendedItemId AND BlendedItemAssets.IsActive=1
INNER JOIN LeaseAssets ON BlendedItemAssets.LeaseAssetId = LeaseAssets.Id
INNER JOIN BlendedItemDetails ON BlendedItems.Id = BlendedItemDetails.BlendedItemId AND BlendedItemDetails.IsActive=1
INNER JOIN GLJournalDetails ON GLJournalDetails.EntityType = 'Contract' AND GLJournalDetails.EntityId = @ContractId AND GLJournalDetails.SourceId = BlendedItemDetails.Id
INNER JOIN GLJournals ON GLJournalDetails.GLJournalId = GLJournals.Id
WHERE LeaseBlendedItems.LeaseFinanceId = @LeaseFinanceId AND GLJournals.IsReversalEntry = 0
GROUP BY LeaseAssets.AssetId,GLJournals.Id,BlendedItems.Id
END
UPDATE AssetValueHistories
SET GLJournalId = #ETCAssetDetails.GLJournalId
FROM AssetValueHistories
JOIN #ETCAssetDetails ON AssetValueHistories.AssetId = #ETCAssetDetails.AssetId AND AssetValueHistories.SourceModuleId = #ETCAssetDetails.SourceId
WHERE AssetValueHistories.SourceModule = @SourceModule AND IsSchedule = 1 AND IsAccounted = 1 and IsLessorOwned = 1
DROP TABLE #ETCAssetDetails
SET NOCOUNT OFF
END

GO
