CREATE TYPE [dbo].[ReceiptApplicationReceivableGroupParam] AS TABLE(
	[AmountApplied] [decimal](16, 2) NULL,
	[TaxApplied] [decimal](16, 2) NULL,
	[BookAmountApplied] [decimal](16, 2) NULL,
	[PreviousAmountApplied] [decimal](16, 2) NULL,
	[PreviousTaxApplied] [decimal](16, 2) NULL,
	[PreviousBookAmountApplied] [decimal](16, 2) NULL,
	[IsReApplication] [bit] NULL,
	[IsActive] [bit] NULL,
	[CustomerId] [bigint] NULL,
	[DueDate] [date] NULL,
	[ReceivableType] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL
)
GO
