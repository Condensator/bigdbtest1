CREATE TYPE [dbo].[PrepaidGLDetailsToUpdate] AS TABLE(
	[ReceiptApplicationReceivableDetailId] [bigint] NULL,
	[IsGLPosted] [bit] NULL,
	[IsTaxGLPosted] [bit] NULL,
	[PrepaidAmount] [decimal](16, 2) NULL,
	[PrepaidTaxAmount] [decimal](16, 2) NULL,
	[LeaseComponentPrepaidAmount] [decimal](16, 2) NULL,
	[NonLeaseComponentPrepaidAmount] [decimal](16, 2) NULL
)
GO
