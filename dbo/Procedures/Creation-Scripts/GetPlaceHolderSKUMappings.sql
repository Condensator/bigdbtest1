SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetPlaceHolderSKUMappings]
(
	@PlaceHolderAssetMap PlaceHolderAssetMap ReadOnly
)
AS
BEGIN
SET NOCOUNT ON

	;WITH CTE_OldAssetSKUs(OldSKUId,Alias)
	AS
	(
	SELECT ASK.Id,ASK.Alias FROM AssetSKUs ASK
	JOIN @PlaceHolderAssetMap PAS ON ASK.AssetId = PAS.AssetId
	),

	CTE_PlaceHolderAssetSKUs(PlaceHolderSKUId,Alias)
	AS
	(
	SELECT ASK.Id,ASK.Alias FROM AssetSKUs ASK
	JOIN @PlaceHolderAssetMap PAS ON ASK.AssetId = PAS.PlaceHolderAssetId
	)

	SELECT CTE_OldAssetSKUs.OldSKUId 'OldAssetSKUId', CTE_PlaceHolderAssetSKUs.PlaceHolderSKUId 'PlaceHolderAssetSKUId'
	FROM CTE_OldAssetSKUs
	JOIN CTE_PlaceHolderAssetSKUs ON CTE_OldAssetSKUs.Alias = CTE_PlaceHolderAssetSKUs.Alias
END

GO
