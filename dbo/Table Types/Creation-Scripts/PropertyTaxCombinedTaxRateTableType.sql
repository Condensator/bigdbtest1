CREATE TYPE [dbo].[PropertyTaxCombinedTaxRateTableType] AS TABLE(
	[AssetId] [bigint] NULL,
	[TaxAreaId] [bigint] NULL,
	[TaxRate] [decimal](10, 6) NULL
)
GO
