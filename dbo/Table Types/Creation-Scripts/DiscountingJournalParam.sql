CREATE TYPE [dbo].[DiscountingJournalParam] AS TABLE(
	[PostDate] [datetime] NULL,
	[IsManualEntry] [bit] NULL,
	[IsReversalEntry] [bit] NULL,
	[LegalEntityId] [bigint] NULL,
	[UniqueIdentifier] [bigint] NULL
)
GO
