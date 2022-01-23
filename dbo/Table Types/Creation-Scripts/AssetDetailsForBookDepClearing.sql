CREATE TYPE [dbo].[AssetDetailsForBookDepClearing] AS TABLE(
	[AssetId] [bigint] NULL,
	[ClearTillDate] [datetimeoffset](7) NULL
)
GO
