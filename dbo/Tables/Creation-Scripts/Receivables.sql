SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Receivables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](2) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[DueDate] [date] NOT NULL,
	[IsDSL] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[InvoiceComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceReceivableGroupingOption] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[IncomeType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[PaymentScheduleId] [bigint] NULL,
	[IsCollected] [bit] NOT NULL,
	[IsServiced] [bit] NOT NULL,
	[IsDummy] [bit] NOT NULL,
	[IsPrivateLabel] [bit] NOT NULL,
	[SourceTable] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[SourceId] [bigint] NULL,
	[TotalAmount_Amount] [decimal](16, 2) NOT NULL,
	[TotalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalBalance_Amount] [decimal](16, 2) NOT NULL,
	[TotalBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalEffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[TotalEffectiveBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalBookBalance_Amount] [decimal](16, 2) NULL,
	[TotalBookBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[CustomerId] [bigint] NULL,
	[FunderId] [bigint] NULL,
	[RemitToId] [bigint] NOT NULL,
	[TaxRemitToId] [bigint] NOT NULL,
	[LocationId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ExchangeRate] [decimal](20, 10) NULL,
	[AlternateBillingCurrencyId] [bigint] NULL,
	[CalculatedDueDate] [date] NULL,
	[CreationSourceTable] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[CreationSourceId] [bigint] NULL,
	[ReceivableTaxType] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[DealCountryId] [bigint] NULL,
	[TaxSourceDetailId] [bigint] NULL,
	[UniqueIdentifier] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Receivables] ADD  CONSTRAINT [DF_Receivables_ReceivableTaxType]  DEFAULT ('None') FOR [ReceivableTaxType]
GO
ALTER TABLE [dbo].[Receivables]  WITH CHECK ADD  CONSTRAINT [EReceivable_AlternateBillingCurrency] FOREIGN KEY([AlternateBillingCurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[Receivables] CHECK CONSTRAINT [EReceivable_AlternateBillingCurrency]
GO
ALTER TABLE [dbo].[Receivables]  WITH CHECK ADD  CONSTRAINT [EReceivable_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[Receivables] CHECK CONSTRAINT [EReceivable_Customer]
GO
ALTER TABLE [dbo].[Receivables]  WITH CHECK ADD  CONSTRAINT [EReceivable_Funder] FOREIGN KEY([FunderId])
REFERENCES [dbo].[Funders] ([Id])
GO
ALTER TABLE [dbo].[Receivables] CHECK CONSTRAINT [EReceivable_Funder]
GO
ALTER TABLE [dbo].[Receivables]  WITH CHECK ADD  CONSTRAINT [EReceivable_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[Receivables] CHECK CONSTRAINT [EReceivable_LegalEntity]
GO
ALTER TABLE [dbo].[Receivables]  WITH CHECK ADD  CONSTRAINT [EReceivable_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[Receivables] CHECK CONSTRAINT [EReceivable_Location]
GO
ALTER TABLE [dbo].[Receivables]  WITH CHECK ADD  CONSTRAINT [EReceivable_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[Receivables] CHECK CONSTRAINT [EReceivable_ReceivableCode]
GO
ALTER TABLE [dbo].[Receivables]  WITH CHECK ADD  CONSTRAINT [EReceivable_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[Receivables] CHECK CONSTRAINT [EReceivable_RemitTo]
GO
ALTER TABLE [dbo].[Receivables]  WITH CHECK ADD  CONSTRAINT [EReceivable_TaxRemitTo] FOREIGN KEY([TaxRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[Receivables] CHECK CONSTRAINT [EReceivable_TaxRemitTo]
GO
ALTER TABLE [dbo].[Receivables]  WITH CHECK ADD  CONSTRAINT [EReceivable_TaxSourceDetail] FOREIGN KEY([TaxSourceDetailId])
REFERENCES [dbo].[TaxSourceDetails] ([Id])
GO
ALTER TABLE [dbo].[Receivables] CHECK CONSTRAINT [EReceivable_TaxSourceDetail]
GO
