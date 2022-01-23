CREATE TYPE [dbo].[SundryInactivation_LeaseInput] AS TABLE(
	[LeaseFinanceId] [bigint] NOT NULL,
	[PayoffEffectiveDate] [date] NOT NULL,
	[IsAdvanceLease] [bit] NOT NULL
)
GO
