CREATE TYPE [dbo].[StaticHistoryAssetHistory] AS TABLE(
	[AsofDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetStatus] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ParentAssetAlias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[AcquisitionDate] [date] NULL,
	[Contract] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[StaticHistoryAssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
