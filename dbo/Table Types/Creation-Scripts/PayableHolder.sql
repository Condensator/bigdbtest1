CREATE TYPE [dbo].[PayableHolder] AS TABLE(
	[Amount] [decimal](18, 2) NULL,
	[BalanceAmount] [decimal](18, 2) NULL,
	[DueDate] [datetime] NULL,
	[ApprovalStatus] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[Source] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[SourceId] [bigint] NULL,
	[InternalComment] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CurrencyId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[PayeeId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL
)
GO
