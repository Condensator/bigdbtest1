SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdatePropertyTaxCombinedTaxRate]
(
@PropertyTaxCombinedTaxRateDetails PropertyTaxCombinedTaxRateTableType READONLY,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
UPDATE PropertyTaxCombinedTaxRates
SET PropertyTaxCombinedTaxRates.TaxRate = PPT_Temp.TaxRate,
PropertyTaxCombinedTaxRates.UpdatedById = @CreatedById,
PropertyTaxCombinedTaxRates.UpdatedTime = @CreatedTime
FROM PropertyTaxCombinedTaxRates
JOIN @PropertyTaxCombinedTaxRateDetails PPT_Temp
ON PropertyTaxCombinedTaxRates.TaxAreaId = PPT_Temp.TaxAreaId AND PropertyTaxCombinedTaxRates.AssetId = PPT_Temp.AssetId
AND PropertyTaxCombinedTaxRates.IsActive = 1
END

GO
