CREATE TYPE [dbo].[NonAccrualNonDSLReceiptInfo] AS TABLE(
	[ReceiptId] [bigint] NULL,
	[ReceiptApplicationId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NULL,
	[BookAmountApplied] [decimal](16, 2) NULL,
	[ReceivableId] [bigint] NULL
)
GO
