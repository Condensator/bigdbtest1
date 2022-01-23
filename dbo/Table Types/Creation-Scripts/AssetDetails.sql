CREATE TYPE [dbo].[AssetDetails] AS TABLE(
	[AssetFeatureId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[Alias] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Prorate] [decimal](18, 10) NULL,
	[NewAmount] [decimal](18, 10) NULL,
	[Quantity] [int] NULL,
	[IsLastAsset] [tinyint] NULL
)
GO
