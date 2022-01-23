CREATE TYPE [dbo].[AlternateBillingCurrencyDetails] AS TABLE(
	[LeasePaymentScheduleId] [bigint] NOT NULL,
	[BillingCurrencyId] [bigint] NULL,
	[BillingExchangeRate] [decimal](18, 8) NULL
)
GO
