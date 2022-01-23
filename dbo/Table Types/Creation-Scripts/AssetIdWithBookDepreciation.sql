CREATE TYPE [dbo].[AssetIdWithBookDepreciation] AS TABLE(
	[AssetId] [bigint] NOT NULL,
	INDEX [IX_AssetId] NONCLUSTERED 
(
	[AssetId] ASC
)
)
GO
