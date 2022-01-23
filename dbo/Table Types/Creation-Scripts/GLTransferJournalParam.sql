CREATE TYPE [dbo].[GLTransferJournalParam] AS TABLE(
	[PostDate] [datetime] NULL,
	[IsManualEntry] [bit] NULL,
	[IsReversalEntry] [bit] NULL,
	[LegalEntityId] [bigint] NULL,
	[SourceId] [bigint] NULL,
	[UniqueIdentifier] [bigint] NULL
)
GO
