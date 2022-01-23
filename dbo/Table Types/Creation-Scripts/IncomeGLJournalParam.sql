CREATE TYPE [dbo].[IncomeGLJournalParam] AS TABLE(
	[UniqueId] [bigint] NULL,
	[PostDate] [datetime] NULL,
	[IsManualEntry] [bit] NULL,
	[IsReversalEntry] [bit] NULL,
	[LegalEntityId] [bigint] NULL
)
GO
