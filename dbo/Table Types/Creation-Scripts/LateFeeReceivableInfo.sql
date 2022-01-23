CREATE TYPE [dbo].[LateFeeReceivableInfo] AS TABLE(
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[DueDate] [date] NULL,
	[ReceiptId] [bigint] NULL,
	[LateFeeAmount] [decimal](16, 2) NULL,
	[EntityId] [bigint] NULL,
	[DaysDue] [int] NULL,
	[LateFeeTemplateId] [bigint] NULL,
	[InvoiceId] [bigint] NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[FullyAssessed] [bit] NULL,
	[AlternateBillingCurrencyId] [bigint] NULL,
	[ExchangeRate] [decimal](18, 8) NULL,
	[TaxBasisAmount] [decimal](16, 2) NULL
)
GO
