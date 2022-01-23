CREATE TYPE [dbo].[CPUParam] AS TABLE(
	[SourceTable] [nvarchar](48) COLLATE Latin1_General_CI_AS NULL,
	[SourceId] [bigint] NULL,
	[Amount] [decimal](16, 2) NULL,
	[Balance] [decimal](16, 2) NULL,
	[TaxPortion] [decimal](16, 2) NULL,
	[DueDate] [date] NULL,
	[Status] [nvarchar](34) COLLATE Latin1_General_CI_AS NULL,
	[IsGLPosted] [bit] NULL,
	[EntityType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[EntityId] [bigint] NULL,
	[IsFromReceipt] [bit] NULL,
	[PassThroughPercentage] [decimal](16, 2) NULL,
	[DefaultAmount] [decimal](16, 2) NULL,
	[ContractSequenceNumber] [nvarchar](80) COLLATE Latin1_General_CI_AS NULL,
	[ContractCurrencyId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NULL,
	[Currency] [bigint] NULL,
	[PayableCode] [bigint] NULL,
	[LegalEntity] [bigint] NULL,
	[RemitTo] [bigint] NULL,
	[Payee] [bigint] NULL
)
GO
