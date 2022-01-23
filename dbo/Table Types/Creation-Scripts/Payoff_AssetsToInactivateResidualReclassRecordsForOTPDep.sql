CREATE TYPE [dbo].[Payoff_AssetsToInactivateResidualReclassRecordsForOTPDep] AS TABLE(
	[AssetId] [bigint] NULL,
	[IsLeaseComponent] [bit] NULL,
	[ReversalGLJournalId] [bigint] NULL,
	[ReversalPostDate] [date] NULL,
	[IsFailedSaleLeaseBack] [bit] NULL
)
GO
