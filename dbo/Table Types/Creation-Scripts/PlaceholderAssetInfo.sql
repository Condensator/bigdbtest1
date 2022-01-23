CREATE TYPE [dbo].[PlaceholderAssetInfo] AS TABLE(
	[AssetId] [bigint] NULL,
	[NBV] [decimal](16, 2) NULL,
	[IsNegativeReturn] [bit] NULL,
	[PlaceHolderAssetCount] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[IsLeaseAsset] [bit] NULL
)
GO
