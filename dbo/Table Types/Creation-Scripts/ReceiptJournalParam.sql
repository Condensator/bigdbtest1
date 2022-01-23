CREATE TYPE [dbo].[ReceiptJournalParam] AS TABLE(
	[PostDate] [date] NULL,
	[IsManualEntry] [bit] NULL,
	[IsReversalEntry] [bit] NULL,
	[LegalEntityId] [bigint] NULL,
	[SourceId] [bigint] NULL,
	[SourceType] [varchar](15) COLLATE Latin1_General_CI_AS NULL,
	[AssetValueHistoryIds] [varchar](max) COLLATE Latin1_General_CI_AS NULL,
	[UniqueIdentifier] [bigint] NULL
)
GO
