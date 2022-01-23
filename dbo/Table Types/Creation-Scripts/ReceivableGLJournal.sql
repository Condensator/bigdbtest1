CREATE TYPE [dbo].[ReceivableGLJournal] AS TABLE(
	[PostDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLJournalId] [bigint] NOT NULL,
	[ReversalGLJournalOfId] [bigint] NULL,
	[ReceivableId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
