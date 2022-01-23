CREATE TYPE [dbo].[AssetSaleAssetInfoParamType] AS TABLE(
	[AssetId] [bigint] NOT NULL,
	[AssetStatus] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL
)
GO
