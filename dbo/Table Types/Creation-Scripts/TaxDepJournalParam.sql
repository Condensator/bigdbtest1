CREATE TYPE [dbo].[TaxDepJournalParam] AS TABLE(
	[RecordCount] [bigint] NULL,
	[PostDate] [datetime] NULL,
	[IsManualEntry] [bit] NULL,
	[IsReversalEntry] [bit] NULL,
	[LegalEntityId] [bigint] NULL,
	[ContractId] [bigint] NULL
)
GO
