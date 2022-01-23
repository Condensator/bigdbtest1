CREATE TYPE [dbo].[AssetTableType] AS TABLE(
	[AssetId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[LeaseTaxAssetId] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CityTaxTypeId] [bigint] NULL,
	[StateTaxtypeId] [bigint] NULL,
	[CountyTaxTypeId] [bigint] NULL
)
GO
