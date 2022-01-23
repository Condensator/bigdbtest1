CREATE TYPE [dbo].[FloatRateIndexDetail] AS TABLE(
	[BaseRate] [decimal](10, 6) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[IsModified] [bit] NOT NULL,
	[IsRateUsed] [bit] NOT NULL,
	[FloatRateIndexId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
