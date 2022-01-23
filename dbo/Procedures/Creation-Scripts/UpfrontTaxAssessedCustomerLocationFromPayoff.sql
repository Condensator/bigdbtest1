SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpfrontTaxAssessedCustomerLocationFromPayoff]
(
	@UpfrontPayoffCustomerLocation UpfrontPayoffCustomerLocation READONLY,
	@PayoffStatus	NVARCHAR(100),
	@UpdatedById	BIGINT,
	@UpdatedTime	DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON


SELECT
	CCL.Id ContractCustomerLocationId, POA.Id PayoffAssetId 
INTO #UpfrontTaxAssessedCustomerLocation
FROM @UpfrontPayoffCustomerLocation UPO
JOIN Payoffs PO ON UPO.LeaseFinanceId = PO.LeaseFinanceId AND UPO.QuoteNumber = PO.QuoteNumber
	AND PO.Status = @PayoffStatus AND PO.FullPayoff = 1
JOIN PayoffAssets POA ON PO.Id = POA.PayoffId 
	AND POA.IsActive = 1
JOIN CustomerLocations CL ON CL.CustomerId = UPO.CustomerId
JOIN ContractCustomerLocations CCL ON 
	CCL.ContractId = UPO.ContractId AND CL.Id = CCL.CustomerLocationId
	AND CCL.UpfrontTaxAssessedInLegacySystem = 1

UPDATE PA
	SET PA.UpfrontTaxAssessedCustomerLocationId = UT.ContractCustomerLocationId
FROM PayoffAssets PA
JOIN #UpfrontTaxAssessedCustomerLocation UT ON PA.Id = UT.PayoffAssetId
;

UPDATE AL
	SET AL.UpfrontTaxAssessedInLegacySystem = CAST(0 AS BIT)
FROM ContractCustomerLocations AL 
JOIN #UpfrontTaxAssessedCustomerLocation UAL ON AL.Id = UAL.ContractCustomerLocationId
;

END

GO
