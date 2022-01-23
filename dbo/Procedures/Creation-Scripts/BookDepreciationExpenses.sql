SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[BookDepreciationExpenses]
(
@FromAssetID BIGINT = NULL,
@ToAssetID BIGINT = NULL,
@LegalEntity NVARCHAR(MAX) = NULL,
@Customer NVARCHAR(MAX) = NULL,
@Year INT = NULL,
@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT OFF;

CREATE TABLE #InvalidAssetIds(
	AssetId BIGINT PRIMARY KEY
);

--Offline Processing Impact
--InActive Assets belonging to pending Contracts will still be shown
INSERT INTO #InvalidAssetIds(AssetId)
SELECT LA.AssetId
FROM LeaseAssets LA
INNER JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id AND LA.IsActive = 1 AND LF.IsCurrent = 1
INNER JOIN Contracts C ON LF.ContractId = C.Id
WHERE C.BackgroundProcessingPending = 1 AND LA.AssetId IS NOT NULL AND
(
	(
		@ToAssetID IS NULL 
			AND (@FromAssetID IS NULL OR LA.[AssetId] = @FromAssetID )
	) 
	OR 
	(
		@ToAssetID IS NOT NULL AND LA.[AssetId] >= @FromAssetID AND LA.[AssetId] <= @ToAssetID 
	)
);

CREATE TABLE #BookDepExpenseTemp(
	AssetId BIGINT NOT NULL,
	AssetTypeName NVARCHAR(100),
	PartyName NVARCHAR(250),
	[Location] NVARCHAR(MAX),
	LegalEntityNumber NVARCHAR(20) 
)

INSERT INTO #BookDepExpenseTemp(AssetId, AssetTypeName, PartyName, [Location], LegalEntityNumber)
select 
	assets.Id,
	[types].[Name],
	p.PartyName,
	ISNULL([location].City+',','')+ISNULL(ISNULL(EntityResourcesForState.[Value],states.LongName),''),
	LE.LegalEntityNumber
FROM Assets assets
INNER JOIN AssetTypes [types] ON [types].Id = assets.TypeId
INNER JOIN LegalEntities LE ON assets.LegalEntityId = LE.Id
LEFT JOIN AssetLocations assetlocation ON assets.Id = assetlocation.AssetId  AND assetlocation.IsCurrent = 1 AND assetlocation.IsActive = 1
LEFT JOIN Locations [location] ON assetlocation.LocationId = [location].Id
LEFT JOIN States states ON [location].StateId = states.Id
LEFT JOIN dbo.Parties p ON assets.CustomerId = p.Id
LEFT JOIN EntityResources EntityResourcesForState ON states.Id = EntityResourcesForState.EntityId
	AND EntityResourcesForState.EntityType = 'State'
	AND EntityResourcesForState.Name = 'LongName'
	AND EntityResourcesForState.Culture = @Culture
LEFT JOIN #InvalidAssetIds ON assets.Id = #InvalidAssetIds.AssetId
WHERE 
#InvalidAssetIds.AssetId IS NULL
AND (LE.LegalEntityNumber = @LegalEntity OR LE.LegalEntityNumber in (select value from string_split(@LegalEntity,',')))
AND (
		(
			@ToAssetID IS NULL 
				AND (@FromAssetID IS NULL OR assets.[Id] = @FromAssetID )
		) 
		OR 
		(
			@ToAssetID IS NOT NULL AND assets.[Id] >= @FromAssetID AND assets.[Id] <= @ToAssetID 
		)
)
AND (p.PartyName = @Customer OR @Customer IS NULL)

SELECT 
	Temp.LegalEntityNumber,
	Temp.PartyName, 
	Temp.AssetId AS [Asset ID],
	Temp.AssetTypeName AS [Asset Type],
	Temp.[Location],
	DATEPART(yyyy, assetvaluehistory.IncomeDate) As 'Year',
	SUM(assetvaluehistory.Value_Amount) AS 'Depreciation Amount'
FROM #BookDepExpenseTemp Temp 
INNER JOIN AssetValueHistories assetvaluehistory ON assetvaluehistory.AssetId = Temp.AssetId
WHERE assetvaluehistory.SourceModule != 'ResidualRecapture'
AND assetvaluehistory.SourceModule IN ('InventoryBookDepreciation','OTPDepreciation','FixedTermDepreciation')
AND assetvaluehistory.IsAccounted = 1
AND assetvaluehistory.IsLessorOwned = 1
AND (DATEPART(yyyy,assetvaluehistory.IncomeDate) <= @Year OR @Year IS NULL)
GROUP BY Temp.AssetId, Temp.AssetTypeName, Temp.[Location], Temp.LegalEntityNumber, Temp.PartyName, DATEPART(yyyy,assetvaluehistory.IncomeDate)

DROP TABLE #BookDepExpenseTemp;
DROP TABLE #InvalidAssetIds;
END

GO
