CREATE TYPE [dbo].[AssetSplitAssetDetail] AS TABLE(
	[NewAssetCost_Amount] [decimal](16, 2) NOT NULL,
	[NewAssetCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NewQuantity] [int] NOT NULL,
	[NewAssetId] [bigint] NULL,
	[AssetFeatureId] [bigint] NULL,
	[AssetSplitAssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
