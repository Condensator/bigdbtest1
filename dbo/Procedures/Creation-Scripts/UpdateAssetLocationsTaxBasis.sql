SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateAssetLocationsTaxBasis]
(
@TaxBasisLocationParam TaxBasisLocationParam READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
UPDATE AssetLocations
SET
AssetLocations.TaxBasisType = ALTemp.TaxBasisType,
AssetLocations.UpdatedTime = @UpdatedTime,
AssetLocations.UpdatedById = @UpdatedById
FROM AssetLocations
JOIN @TaxBasisLocationParam ALTemp ON ALTemp.CustomerAssetLocationId = AssetLocations.Id
END

GO
