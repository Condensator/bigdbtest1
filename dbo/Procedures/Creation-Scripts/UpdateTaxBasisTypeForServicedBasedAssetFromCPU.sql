SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateTaxBasisTypeForServicedBasedAssetFromCPU]
(
@AssetIdsCSV NVARCHAR(Max),
@UpdatedById bigint,
@UpdatedTime DATETIMEOFFSET,
@SteamTaxBasisType NVARCHAR(20),
@UnknownTaxBasisType NVARCHAR(20)
)
As

SELECT * INTO #ServiceAssetIds FROM ConvertCSVToBigIntTable(@AssetIdsCSV,',')

UPDATE AL SET AL.TaxBasisType = @SteamTaxBasisType,AL.UpdatedById = @UpdatedById, AL.UpdatedTime = @UpdatedTime
FROM AssetLocations AL 
JOIN #ServiceAssetIds SAId ON AL.AssetId = SAId.Id
WHERE AL.IsActive=1 AND AL.TaxBasisType=@UnknownTaxBasisType


DROP TABLE #ServiceAssetIds

GO
