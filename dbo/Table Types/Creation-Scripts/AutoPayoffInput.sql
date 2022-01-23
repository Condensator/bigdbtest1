CREATE TYPE [dbo].[AutoPayoffInput] AS TABLE(
	[LeaseFinanceId] [bigint] NOT NULL,
	[AutoPayoffTemplateId] [bigint] NOT NULL,
	[PayoffEffectiveDate] [date] NOT NULL,
	[PayoffAtFixedTerm] [bit] NOT NULL,
	[ActivatePayoffQuote] [bit] NOT NULL
)
GO
