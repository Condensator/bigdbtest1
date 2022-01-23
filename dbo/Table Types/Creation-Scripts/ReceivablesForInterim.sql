CREATE TYPE [dbo].[ReceivablesForInterim] AS TABLE(
	[Identifier] [bigint] NULL,
	[PaymentScheduleIdentifier] [bigint] NULL,
	[SourceIdentifier] [bigint] NULL,
	[EntityId] [bigint] NULL,
	[DueDate] [date] NULL,
	[InvoiceComment] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableCodeId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[PaymentScheduleId] [bigint] NULL,
	[IsDSL] [bit] NULL,
	[IsServiced] [bit] NULL,
	[IsCollected] [bit] NULL,
	[IsPrivateLabel] [bit] NULL,
	[IsDummy] [bit] NULL,
	[InvoiceReceivableGroupingOption] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[FunderId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalBookBalance] [decimal](16, 2) NULL,
	[ReceivableAmount] [decimal](16, 2) NULL,
	[SourceId] [bigint] NULL,
	[SourceTable] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[AlternateBillingCurrencyId] [bigint] NULL,
	[ExchangeRate] [decimal](20, 10) NULL,
	[LocationId] [bigint] NULL,
	[ReceivableDetailAmount] [decimal](16, 2) NULL,
	[ReceivableDetailBalance] [decimal](16, 2) NULL,
	[ReceivableDetailEffectiveBalance] [decimal](16, 2) NULL,
	[ReceivableDetailEffectiveBookBalance] [decimal](16, 2) NULL,
	[ReceivableDetailBillToId] [bigint] NULL,
	[ReceivableDetailIsTaxAssessed] [bit] NULL,
	[CalculatedDueDate] [date] NULL,
	[AdjustmentBasisReceivableDetailId] [bigint] NULL
)
GO