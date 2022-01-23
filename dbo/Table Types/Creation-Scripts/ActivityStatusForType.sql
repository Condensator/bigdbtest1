CREATE TYPE [dbo].[ActivityStatusForType] AS TABLE(
	[Sequence] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[StatusId] [bigint] NOT NULL,
	[WhomToNotifyId] [bigint] NOT NULL,
	[WhoCanChangeId] [bigint] NOT NULL,
	[ActivityTypeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
