CREATE TYPE [dbo].[AssetValueHistoriesInGLOpenPeriodParam] AS TABLE(
	[AVHId] [bigint] NULL,
	[IsAccounted] [bit] NULL,
	[IsSchedule] [bit] NULL,
	[ReversalGLJournalId] [bigint] NULL,
	[ReversalPostDate] [datetime] NULL
)
GO
