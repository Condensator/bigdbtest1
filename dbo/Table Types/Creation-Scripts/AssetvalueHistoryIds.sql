CREATE TYPE [dbo].[AssetvalueHistoryIds] AS TABLE(
	[Id] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[PostDate] [date] NULL,
	[ReversalGLJournalId] [bigint] NULL,
	[ReversalPostDate] [date] NULL
)
GO
