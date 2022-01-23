CREATE TYPE [dbo].[ReceiptGLJournal] AS TABLE(
	[PostDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsReversal] [bit] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[GLJournalId] [bigint] NOT NULL,
	[ReceiptId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
