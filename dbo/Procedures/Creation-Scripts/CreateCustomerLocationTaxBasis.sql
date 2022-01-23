SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CreateCustomerLocationTaxBasis]
(
@TaxBasisLocationParam TaxBasisLocationParam READONLY,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
	INSERT INTO ContractCustomerLocations
	(
		CustomerLocationId,
		ContractId,
		TaxBasisType,
		CreatedById,
		CreatedTime,
		UpfrontTaxAssessedInLegacySystem
	)
	SELECT
		CustomerTaxBasis.CustomerAssetLocationId,
		CustomerTaxBasis.ContractId,
		CustomerTaxBasis.TaxBasisType,
		@CreatedById,
		@CreatedTime,
		CAST(0 AS BIT)
	FROM @TaxBasisLocationParam AS CustomerTaxBasis
	LEFT JOIN ContractCustomerLocations CCL ON CustomerTaxBasis.ContractId = CCL.ContractId
	AND CustomerTaxBasis.CustomerAssetLocationId = CCL.CustomerLocationId
	WHERE CCL.ContractId IS NULL

END

GO
