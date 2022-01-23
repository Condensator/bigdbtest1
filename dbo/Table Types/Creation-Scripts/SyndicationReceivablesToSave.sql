CREATE TYPE [dbo].[SyndicationReceivablesToSave] AS TABLE(
	[EntityType] [nvarchar](2) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[DueDate] [date] NOT NULL,
	[IsDSL] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceReceivableGroupingOption] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[IncomeType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[PaymentScheduleId] [bigint] NULL,
	[IsCollected] [bit] NOT NULL,
	[IsServiced] [bit] NOT NULL,
	[IsDummy] [bit] NOT NULL,
	[IsPrivateLabel] [bit] NOT NULL,
	[SourceTable] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[SourceId] [bigint] NULL,
	[TotalAmount_Amount] [decimal](16, 2) NOT NULL,
	[TotalBalance_Amount] [decimal](16, 2) NOT NULL,
	[TotalEffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[TotalBookBalance_Amount] [decimal](16, 2) NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[CustomerId] [bigint] NULL,
	[FunderId] [bigint] NULL,
	[RemitToId] [bigint] NOT NULL,
	[TaxRemitToId] [bigint] NOT NULL,
	[LocationId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[AlternateBillingCurrencyId] [bigint] NULL,
	[ExchangeRate] [decimal](18, 8) NULL
)
GO