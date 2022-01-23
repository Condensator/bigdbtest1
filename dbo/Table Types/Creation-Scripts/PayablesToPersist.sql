CREATE TYPE [dbo].[PayablesToPersist] AS TABLE(
	[Identifier] [bigint] NULL,
	[SourceIdentifier] [bigint] NULL,
	[EntityType] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[EntityId] [bigint] NULL,
	[DueDate] [date] NULL,
	[InternalComment] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[SourceId] [bigint] NULL,
	[SourceTable] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Amount] [decimal](16, 2) NULL,
	[LegalEntityId] [bigint] NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CurrencyId] [bigint] NULL,
	[PayeeId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL
)
GO
