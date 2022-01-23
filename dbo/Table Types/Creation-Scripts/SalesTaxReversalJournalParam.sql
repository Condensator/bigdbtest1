CREATE TYPE [dbo].[SalesTaxReversalJournalParam] AS TABLE(
	[PostDate] [datetime] NULL,
	[IsManualEntry] [bit] NULL,
	[IsReversalEntry] [bit] NULL,
	[LegalEntityId] [bigint] NULL,
	[SourceId] [bigint] NULL
)
GO
