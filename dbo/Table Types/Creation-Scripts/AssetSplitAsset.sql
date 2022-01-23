CREATE TYPE [dbo].[AssetSplitAsset] AS TABLE(
	[SplitByType] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OriginalAssetCost_Amount] [decimal](16, 2) NOT NULL,
	[OriginalAssetCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OriginalQuantity] [int] NOT NULL,
	[OriginalAssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
