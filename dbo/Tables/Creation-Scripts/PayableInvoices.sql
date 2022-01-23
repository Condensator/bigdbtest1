SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayableInvoices](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[InvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[OriginalInvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceDate] [date] NULL,
	[DueDate] [date] NOT NULL,
	[Alias] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceTotal_Amount] [decimal](16, 2) NOT NULL,
	[InvoiceTotal_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalAssetCost_Amount] [decimal](16, 2) NOT NULL,
	[TotalAssetCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NumberOfAssets] [int] NOT NULL,
	[IsForeignCurrency] [bit] NOT NULL,
	[InitialExchangeRate] [decimal](20, 10) NULL,
	[Balance_Amount] [decimal](16, 2) NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AllowCreateAssets] [bit] NOT NULL,
	[PostDate] [date] NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsOtherCostDistributionRequired] [bit] NOT NULL,
	[IsAttachedInTransaction] [bit] NOT NULL,
	[IsSystemGenerated] [bit] NOT NULL,
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsSalesLeaseBack] [bit] NOT NULL,
	[Revise] [bit] NOT NULL,
	[SourceTransaction] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[OriginalExchangeRate] [decimal](20, 10) NULL,
	[IsInvalidPayableInvoice] [bit] NOT NULL,
	[PayableInvoiceDocumentInstance_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[PayableInvoiceDocumentInstance_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[PayableInvoiceDocumentInstance_Content] [varbinary](82) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[VendorId] [bigint] NOT NULL,
	[AssetCostPayableCodeId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[ContractCurrencyId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[ReversalGLJournalId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[ParentPayableInvoiceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[VendorNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[CountryId] [bigint] NULL,
	[AssetCostWithholdingTaxRate] [decimal](5, 2) NULL,
	[DisbursementWithholdingTaxRate] [decimal](5, 2) NULL,
	[IsOriginalInvoice] [bit] NOT NULL,
	[OriginalInvoiceDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_AssetCostPayableCode] FOREIGN KEY([AssetCostPayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_AssetCostPayableCode]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_Branch]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_Contract]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_ContractCurrency] FOREIGN KEY([ContractCurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_ContractCurrency]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_CostCenter]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_Country]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_Currency]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_Customer]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_GLJournal]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_InstrumentType]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_LegalEntity]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_LineofBusiness]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_ParentPayableInvoice] FOREIGN KEY([ParentPayableInvoiceId])
REFERENCES [dbo].[PayableInvoices] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_ParentPayableInvoice]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_RemitTo]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_ReversalGLJournal] FOREIGN KEY([ReversalGLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_ReversalGLJournal]
GO
ALTER TABLE [dbo].[PayableInvoices]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoices] CHECK CONSTRAINT [EPayableInvoice_Vendor]
GO
