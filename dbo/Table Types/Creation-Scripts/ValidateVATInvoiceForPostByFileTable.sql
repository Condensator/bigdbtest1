CREATE TYPE [dbo].[ValidateVATInvoiceForPostByFileTable] AS TABLE(
	[InvoiceNumber] [nvarchar](80) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableInvoiceId] [bigint] NULL,
	[ReceiptAmount] [decimal](16, 2) NULL,
	[ReceivableDetailId] [bigint] NULL,
	[GroupNumber] [bigint] NULL
)
GO
