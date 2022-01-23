CREATE TYPE [dbo].[AssetToUpdateStatus] AS TABLE(
	[AssetId] [bigint] NOT NULL,
	[AssetStatus] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL
)
GO
