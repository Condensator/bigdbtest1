CREATE TYPE [dbo].[AssetSplitDetail] AS TABLE(
	[SplitInto] [int] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TotalQuantity] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[OriginalAssetId] [bigint] NOT NULL,
	[AssetSplitId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
