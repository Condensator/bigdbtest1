CREATE TYPE [dbo].[PayoffReceivablesGLPostingResult] AS TABLE(
	[EntityId] [bigint] NOT NULL,
	[GLJournalId] [bigint] NOT NULL,
	[IsTaxReceivable] [bit] NOT NULL
)
GO
