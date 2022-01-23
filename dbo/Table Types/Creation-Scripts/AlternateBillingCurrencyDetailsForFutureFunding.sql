CREATE TYPE [dbo].[AlternateBillingCurrencyDetailsForFutureFunding] AS TABLE(
	[LeasePaymentScheduleId] [bigint] NULL,
	[BillingCurrencyId] [bigint] NULL,
	[BillingExchangeRate] [decimal](18, 8) NULL
)
GO
