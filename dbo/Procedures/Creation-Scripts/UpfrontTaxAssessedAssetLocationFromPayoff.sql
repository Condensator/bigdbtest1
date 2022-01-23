SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpfrontTaxAssessedAssetLocationFromPayoff]
(
	@UpfrontPayoffAssetLocation UpfrontPayoffAssetLocation READONLY,
	@PayoffStatus	NVARCHAR(50),
	@UpdatedById	BIGINT,
	@UpdatedTime	DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON


SELECT
	LA.AssetId, AL.Id AssetLocationId, POA.Id PayoffAssetId 
INTO #UpfrontTaxAssessedAssetLocation
FROM @UpfrontPayoffAssetLocation UPA
JOIN Payoffs PO ON UPA.LeaseFinanceId = PO.LeaseFinanceId AND UPA.QuoteNumber = PO.QuoteNumber
	AND PO.Status = @PayoffStatus
JOIN LeaseAssets LA ON UPA.LeaseAssetId = LA.Id AND UPA.AssetId = LA.AssetId
JOIN PayoffAssets POA ON LA.Id = POA.LeaseAssetId AND POA.IsActive = 1
JOIN AssetLocations AL ON LA.AssetId = AL.AssetId AND AL.IsActive = 1
WHERE AL.UpfrontTaxAssessedInLegacySystem = 1
;

UPDATE PA
	SET PA.UpfrontTaxAssessedAssetLocationId = UT.AssetLocationId
FROM PayoffAssets PA
JOIN #UpfrontTaxAssessedAssetLocation UT ON PA.Id = UT.PayoffAssetId
;

UPDATE AL
	SET AL.UpfrontTaxAssessedInLegacySystem = CAST(0 AS BIT)
FROM AssetLocations AL 
JOIN #UpfrontTaxAssessedAssetLocation UAL ON AL.Id = UAL.AssetLocationId
;

END

GO
