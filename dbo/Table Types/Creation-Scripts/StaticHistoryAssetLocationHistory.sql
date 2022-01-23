CREATE TYPE [dbo].[StaticHistoryAssetLocationHistory] AS TABLE(
	[LocationEffectiveFromDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StaticHistoryLocationId] [bigint] NOT NULL,
	[StaticHistoryAssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
