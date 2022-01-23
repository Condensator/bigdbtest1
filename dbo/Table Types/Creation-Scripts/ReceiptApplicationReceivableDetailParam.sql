CREATE TYPE [dbo].[ReceiptApplicationReceivableDetailParam] AS TABLE(
	[AmountApplied] [decimal](16, 2) NULL,
	[TaxApplied] [decimal](16, 2) NULL,
	[BookAmountApplied] [decimal](16, 2) NULL,
	[PreviousAmountApplied] [decimal](16, 2) NULL,
	[PreviousBookAmountApplied] [decimal](16, 2) NULL,
	[PreviousTaxApplied] [decimal](16, 2) NULL,
	[IsGLPosted] [bit] NULL,
	[IsTaxGLPosted] [bit] NULL,
	[RecoveryAmount] [decimal](16, 2) NULL,
	[GainAmount] [decimal](16, 2) NULL,
	[IsReApplication] [bit] NULL,
	[IsActive] [bit] NULL,
	[ReceivableDetailId] [bigint] NULL,
	[ReceivableInvoiceId] [bigint] NULL,
	[AccountingTreatment] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[IsRental] [bit] NULL,
	[ContractId] [bigint] NULL
)
GO
