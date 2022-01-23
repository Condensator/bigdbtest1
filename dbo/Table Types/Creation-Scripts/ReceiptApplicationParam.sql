CREATE TYPE [dbo].[ReceiptApplicationParam] AS TABLE(
	[PostDate] [date] NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AmountApplied] [decimal](16, 2) NULL,
	[IsFullCash] [bit] NULL,
	[CreditApplied] [decimal](16, 2) NULL,
	[ReceivableDisplayOption] [nvarchar](24) COLLATE Latin1_General_CI_AS NULL
)
GO
