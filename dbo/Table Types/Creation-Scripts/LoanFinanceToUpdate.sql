CREATE TYPE [dbo].[LoanFinanceToUpdate] AS TABLE(
	[IsPaymentScheduleModified] [bit] NULL,
	[IsBlendedToBeRecomputed] [bit] NULL,
	[FloatRateUpdateRunDate] [date] NULL,
	[LoanFinanceId] [bigint] NULL,
	[CurrentMaturityDate] [date] NULL,
	[MaturityDate] [date] NULL,
	[Term] [decimal](10, 6) NULL,
	[NumberOfPayments] [bigint] NULL
)
GO
