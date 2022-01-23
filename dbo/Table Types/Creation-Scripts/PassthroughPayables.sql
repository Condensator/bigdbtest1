CREATE TYPE [dbo].[PassthroughPayables] AS TABLE(
	[EntityType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[EntityId] [bigint] NULL,
	[Amount] [decimal](16, 2) NOT NULL,
	[Balance] [decimal](16, 2) NOT NULL,
	[TaxPortion] [decimal](16, 2) NOT NULL,
	[DueDate] [date] NULL,
	[Status] [nvarchar](34) COLLATE Latin1_General_CI_AS NULL,
	[SourceTable] [nvarchar](48) COLLATE Latin1_General_CI_AS NULL,
	[SourceId] [bigint] NULL,
	[InternalComment] [nvarchar](400) COLLATE Latin1_General_CI_AS NULL,
	[IsGLPosted] [bit] NULL,
	[ReceivableDetailId] [bigint] NULL,
	[CurrencyId] [bigint] NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PayableCodeId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[PayeeId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[AdjustmentBasisPayableId] [bigint] NULL,
	[ReceiptId] [bigint] NULL,
	[ReceiptApplicationReceivableDetailId] [bigint] NULL
)
GO
