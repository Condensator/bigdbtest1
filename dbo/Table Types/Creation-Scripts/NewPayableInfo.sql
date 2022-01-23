CREATE TYPE [dbo].[NewPayableInfo] AS TABLE(
	[Key] [bigint] NOT NULL,
	[EntityType] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[Amount] [decimal](16, 2) NOT NULL,
	[Balance] [decimal](16, 2) NOT NULL,
	[Currency] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDate] [date] NOT NULL,
	[PayableStatus] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceTable] [nvarchar](24) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceId] [bigint] NOT NULL,
	[InternalComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsGLPosted] [bit] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[PayableCodeId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[PayeeId] [bigint] NOT NULL,
	[RemitToId] [bigint] NULL,
	[TaxPortion] [decimal](16, 2) NOT NULL,
	[AdjustmentBasisPayableId] [bigint] NULL
)
GO
