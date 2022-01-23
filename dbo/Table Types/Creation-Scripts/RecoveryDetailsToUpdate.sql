CREATE TYPE [dbo].[RecoveryDetailsToUpdate] AS TABLE(
	[ReceiptApplicationReceivableDetailId] [bigint] NULL,
	[RecoveryAmount] [decimal](16, 2) NULL,
	[GainAmount] [decimal](16, 2) NULL
)
GO
