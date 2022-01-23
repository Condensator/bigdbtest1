SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[RevertUpfrontTaxAssessedFlagFromPayoffReversal]
(
@PayoffId			BIGINT,
@TaxAssessmentLevel	NVARCHAR(50),
@UpdatedById		BIGINT,
@UpdatedTime		DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON

SELECT
	POA.Id, POA.UpfrontTaxAssessedAssetLocationId, POA.UpfrontTaxAssessedCustomerLocationId
INTO #PayoffAssets
FROM Payoffs PO
JOIN PayoffAssets POA ON PO.Id = POA.PayoffId
WHERE PO.Id = @PayoffId
;

IF (@TaxAssessmentLevel <> 'Customer')
BEGIN

	UPDATE AL
		SET AL.UpfrontTaxAssessedInLegacySystem = CAST(1 AS BIT),
		UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
	FROM #PayoffAssets POA
	JOIN AssetLocations AL ON POA.UpfrontTaxAssessedAssetLocationId = AL.Id

	UPDATE POA	
		SET POA.UpfrontTaxAssessedAssetLocationId = NULL,
		UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
	FROM PayoffAssets POA
	JOIN #PayoffAssets PA ON POA.Id = PA.Id

END
ELSE
BEGIN
	
	UPDATE AL
		SET AL.UpfrontTaxAssessedInLegacySystem = CAST(1 AS BIT),
		UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
	FROM #PayoffAssets POA
	JOIN ContractCustomerLocations AL ON POA.UpfrontTaxAssessedCustomerLocationId = AL.Id

	UPDATE POA	
		SET POA.UpfrontTaxAssessedCustomerLocationId = NULL,
		UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
	FROM PayoffAssets POA
	JOIN #PayoffAssets PA ON POA.Id = PA.Id

END

END

GO
