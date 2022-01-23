CREATE TYPE [dbo].[StaticHistoryAsset] AS TABLE(
	[LegacyAssetId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetAlias] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
