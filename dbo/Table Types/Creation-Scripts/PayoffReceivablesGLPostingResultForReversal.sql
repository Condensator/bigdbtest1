CREATE TYPE [dbo].[PayoffReceivablesGLPostingResultForReversal] AS TABLE(
	[EntityId] [bigint] NOT NULL,
	[GLJournalId] [bigint] NOT NULL,
	[IsTaxReceivable] [bit] NULL,
	[ReversalGLJournalOfId] [bigint] NULL
)
GO
