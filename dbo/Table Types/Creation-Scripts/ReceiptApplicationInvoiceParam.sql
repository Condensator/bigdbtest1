CREATE TYPE [dbo].[ReceiptApplicationInvoiceParam] AS TABLE(
	[AmountApplied] [decimal](16, 2) NULL,
	[TaxApplied] [decimal](16, 2) NULL,
	[PreviousAmountApplied] [decimal](16, 2) NULL,
	[PreviousTaxApplied] [decimal](16, 2) NULL,
	[IsReApplication] [bit] NULL,
	[IsActive] [bit] NULL,
	[ReceivableInvoiceId] [bigint] NULL
)
GO
