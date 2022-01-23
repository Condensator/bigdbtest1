CREATE TYPE [dbo].[ActivityStatusHistory] AS TABLE(
	[AsOfDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ChangedById] [bigint] NOT NULL,
	[StatusId] [bigint] NOT NULL,
	[ActivityId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
