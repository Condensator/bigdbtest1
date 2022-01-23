CREATE TYPE [dbo].[WithHoldingTaxReportResultType] AS TABLE(
	[TransactionDate] [varchar](30) COLLATE Latin1_General_CI_AS NULL,
	[TransactionType] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptOrPaymentVoucher] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[WithholdingTaxRate] [decimal](16, 2) NULL,
	[WithholdingTaxBase] [decimal](16, 2) NULL,
	[CustomerOrVendor] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[TaxId] [nvarchar](150) COLLATE Latin1_General_CI_AS NULL,
	[Currency] [nvarchar](400) COLLATE Latin1_General_CI_AS NULL,
	[TaxWithheld] [decimal](16, 2) NULL
)
GO
