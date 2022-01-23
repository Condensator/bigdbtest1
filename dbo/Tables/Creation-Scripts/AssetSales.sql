SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetSales](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TransactionNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TransactionDate] [date] NULL,
	[PostDate] [date] NULL,
	[DueDate] [date] NULL,
	[Status] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[TaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[InvoicePreference] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[NumberofInstallment] [int] NOT NULL,
	[SaleOfInvestorAsset] [bit] NOT NULL,
	[IsInstallmentQuote] [bit] NOT NULL,
	[IsGenerateInstallmentPerformed] [bit] NOT NULL,
	[IsTaxAssessed] [bit] NOT NULL,
	[IsAllowTradeIn] [bit] NOT NULL,
	[IsCompletePayableInvoice] [bit] NOT NULL,
	[IsPayableNetoff] [bit] NOT NULL,
	[InvoiceReceivableGroupingOption] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFile_Content] [varbinary](82) NULL,
	[Discounts_Amount] [decimal](16, 2) NOT NULL,
	[Discounts_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsAssignAtAssetLevel] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NULL,
	[GLConfigurationId] [bigint] NULL,
	[BuyerId] [bigint] NOT NULL,
	[BillToId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[TaxLocationId] [bigint] NULL,
	[AssetSaleReceivableCodeId] [bigint] NULL,
	[AssetSaleGLTemplateId] [bigint] NULL,
	[AssetSaleTaxGLTemplateId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[PayableCodeId] [bigint] NULL,
	[PayableInvoiceId] [bigint] NULL,
	[SaleGLJournalId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[RetainedDiscounts_Amount] [decimal](16, 2) NOT NULL,
	[RetainedDiscounts_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CashBasedAssetSaleReceivableCodeId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[TaxDepDisposalTemplateId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[BookGainLossAmount_Amount] [decimal](16, 2) NULL,
	[BookGainLossAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxGainLossAmount_Amount] [decimal](16, 2) NULL,
	[TaxGainLossAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NetSaleAmount_Amount] [decimal](16, 2) NULL,
	[NetSaleAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
	[CountryId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_AssetSaleGLTemplate] FOREIGN KEY([AssetSaleGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_AssetSaleGLTemplate]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_AssetSaleReceivableCode] FOREIGN KEY([AssetSaleReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_AssetSaleReceivableCode]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_AssetSaleTaxGLTemplate] FOREIGN KEY([AssetSaleTaxGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_AssetSaleTaxGLTemplate]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_BillTo]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_Branch]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_Buyer] FOREIGN KEY([BuyerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_Buyer]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_CashBasedAssetSaleReceivableCode] FOREIGN KEY([CashBasedAssetSaleReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_CashBasedAssetSaleReceivableCode]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_CostCenter]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_Country]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_Currency]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_GLConfiguration] FOREIGN KEY([GLConfigurationId])
REFERENCES [dbo].[GLConfigurations] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_GLConfiguration]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_InstrumentType]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_LegalEntity]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_LineofBusiness]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_PayableCode]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_PayableInvoice] FOREIGN KEY([PayableInvoiceId])
REFERENCES [dbo].[PayableInvoices] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_PayableInvoice]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_RemitTo]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_SaleGLJournal] FOREIGN KEY([SaleGLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_SaleGLJournal]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_TaxDepDisposalTemplate] FOREIGN KEY([TaxDepDisposalTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_TaxDepDisposalTemplate]
GO
ALTER TABLE [dbo].[AssetSales]  WITH CHECK ADD  CONSTRAINT [EAssetSale_TaxLocation] FOREIGN KEY([TaxLocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[AssetSales] CHECK CONSTRAINT [EAssetSale_TaxLocation]
GO
