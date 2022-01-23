CREATE TYPE [dbo].[AssetSaleDataType] AS TABLE(
	[LegalEntityName] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[Inventory_AS_GL] [decimal](16, 2) NOT NULL,
	[CostOfGoodsSold_AS_GL] [decimal](16, 2) NOT NULL,
	[AccumulatedAssetDepreciation_AS_GL] [decimal](16, 2) NOT NULL,
	[AccumulatedAssetImpairment_AS_GL] [decimal](16, 2) NOT NULL
)
GO
