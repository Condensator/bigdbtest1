CREATE TYPE [dbo].[UpfrontPayoffAssetLocation] AS TABLE(
	[AssetId] [bigint] NULL,
	[LeaseAssetId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NULL,
	[QuoteNumber] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL
)
GO
