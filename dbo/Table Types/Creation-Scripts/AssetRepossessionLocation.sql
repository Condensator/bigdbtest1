CREATE TYPE [dbo].[AssetRepossessionLocation] AS TABLE(
	[EffectiveFromDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveTillDate] [date] NULL,
	[IsCurrent] [bit] NULL,
	[IsActive] [bit] NULL,
	[LocationId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
