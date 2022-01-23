CREATE TYPE [dbo].[UpdatedAssetValueHistories] AS TABLE(
	[AssetValueHistoryId] [bigint] NOT NULL,
	[IsSchedule] [bit] NOT NULL,
	[IsAccounted] [bit] NOT NULL,
	[ReversalPostDate] [date] NULL,
	[ReversalGLJournalId] [bigint] NULL
)
GO
