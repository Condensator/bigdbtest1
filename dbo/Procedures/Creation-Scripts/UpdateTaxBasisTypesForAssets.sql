SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateTaxBasisTypesForAssets]
	@LeaseFinanceId BIGINT,
	@LocationDate DATE,
	@IsForNewlyAddedAssets BIT,
	@UpdatedById BIGINT,
	@UpdatedTime DateTimeOffset
AS
BEGIN
SET NOCOUNT ON;

	SELECT al.Id AS AssetLocationId, tbt.Name As TaxBasisType, 
	ROW_NUMBER() OVER (PARTITION BY al.AssetId ORDER By al.EffectiveFromDate desc, al.Id desc ) as RowNumber
	INTO #AssetLocationsToUpdate
	FROM dbo.AssetLocations al
	JOIN dbo.LeaseAssets la ON al.AssetId = la.AssetId
	JOIN LeaseTaxAssessmentDetails ltad ON la.LeaseTaxAssessmentDetailId = ltad.Id AND al.LocationId = ltad.LocationId AND LA.LeaseFinanceId= ltad.LeaseFinanceId
	JOIN TaxBasisTypes tbt ON ltad.TaxBasisTypeId = tbt.Id
	WHERE la.LeaseFinanceId = @LeaseFinanceId
			AND al.IsActive = 1
			AND la.IsActive = 1
			AND al.EffectiveFromDate <= @LocationDate
			AND ltad.IsActive = 1
			AND (@IsForNewlyAddedAssets = 0 OR la.IsNewlyAdded = 1);

	UPDATE AssetLocations 
	SET TaxBasisType = #AssetLocationsToUpdate.TaxBasisType, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
	FROM AssetLocations
	JOIN #AssetLocationsToUpdate ON AssetLocations.Id = #AssetLocationsToUpdate.AssetLocationId
	WHERE #AssetLocationsToUpdate.RowNumber = 1;
END

GO
