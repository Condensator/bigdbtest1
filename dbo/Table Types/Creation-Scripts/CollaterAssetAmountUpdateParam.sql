CREATE TYPE [dbo].[CollaterAssetAmountUpdateParam] AS TABLE(
	[ProgressLoanInvoiceId] [bigint] NULL,
	[LoanFinanceId] [bigint] NULL,
	[ExchangeRate] [decimal](10, 6) NULL
)
GO
