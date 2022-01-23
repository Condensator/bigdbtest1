CREATE TYPE [dbo].[PayoffInputForBlendedItemExtract] AS TABLE(
	[LeaseFinanceId] [bigint] NOT NULL,
	[PayoffEffectiveDate] [date] NULL,
	[IsChargedOffLease] [bit] NOT NULL,
	[IsSyndicatedServiced] [bit] NOT NULL
)
GO
