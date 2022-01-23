CREATE TYPE [dbo].[PrepaidReceivableSummary] AS TABLE(
	[ReceivableId] [bigint] NULL,
	[IsGLPosted] [bit] NULL,
	[IsTaxGLPosted] [bit] NULL,
	[TotalReceivableAmountToPostGL] [decimal](16, 2) NULL,
	[TotalTaxAmountToPostGL] [decimal](16, 2) NULL,
	[TotalFinancingReceivableAmountToPostGL] [decimal](16, 2) NULL
)
GO
