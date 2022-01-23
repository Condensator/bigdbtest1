CREATE TYPE [dbo].[ImportedAssets] AS TABLE(
	[AssetId] [bigint] NOT NULL,
	[IsPersisted] [bit] NOT NULL
)
GO
