SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableInvoices](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDate] [date] NOT NULL,
	[IsDummy] [bit] NOT NULL,
	[IsNumberSystemCreated] [bit] NOT NULL,
	[CancellationDate] [date] NULL,
	[InvoiceAmount_Amount] [decimal](16, 2) NOT NULL,
	[InvoiceAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[InvoiceTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxBalance_Amount] [decimal](16, 2) NOT NULL,
	[TaxBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveTaxBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveTaxBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceRunDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsInvoiceCleared] [bit] NOT NULL,
	[SplitByContract] [bit] NOT NULL,
	[SplitByLocation] [bit] NOT NULL,
	[SplitByAsset] [bit] NOT NULL,
	[SplitCreditsByOriginalInvoice] [bit] NOT NULL,
	[SplitByReceivableAdj] [bit] NOT NULL,
	[GenerateSummaryInvoice] [bit] NOT NULL,
	[InvoiceFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFile_Content] [varbinary](82) NULL,
	[IsEmailSent] [bit] NOT NULL,
	[IsPrivateLabel] [bit] NOT NULL,
	[IsACH] [bit] NOT NULL,
	[InvoiceFileName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoicePreference] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[RunTimeComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[OriginationSource] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[OriginationSourceId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NOT NULL,
	[BillToId] [bigint] NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[CancelledById] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[ReceivableCategoryId] [bigint] NOT NULL,
	[ReportFormatId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LastReceivedDate] [date] NULL,
	[IsPdfGenerated] [bit] NOT NULL,
	[DeliveryDate] [date] NULL,
	[DeliveryMethod] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[DeliveryJobStepInstanceId] [bigint] NULL,
	[EmailNotificationId] [bigint] NULL,
	[AlternateBillingCurrencyId] [bigint] NULL,
	[DaysLateCount] [int] NULL,
	[IsStatementInvoice] [bit] NOT NULL,
	[StatementInvoicePreference] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[LastStatementGeneratedDueDate] [date] NULL,
	[WithHoldingTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[WithHoldingTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[WithHoldingTaxBalance_Amount] [decimal](16, 2) NOT NULL,
	[WithHoldingTaxBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CurrencyISO] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceivableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[CustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[RemitToName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[AlternateBillingCurrencyISO] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LegalEntityNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[SplitReceivableDueDate] [bit] NOT NULL,
	[SplitCustomerPurchaseOrderNumber] [bit] NOT NULL,
	[ReceivableTaxType] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[DealCountryId] [bigint] NULL,
	[OriginalInvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableInvoices]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_AlternateBillingCurrency] FOREIGN KEY([AlternateBillingCurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoices] CHECK CONSTRAINT [EReceivableInvoice_AlternateBillingCurrency]
GO
ALTER TABLE [dbo].[ReceivableInvoices]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoices] CHECK CONSTRAINT [EReceivableInvoice_BillTo]
GO
ALTER TABLE [dbo].[ReceivableInvoices]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_CancelledBy] FOREIGN KEY([CancelledById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoices] CHECK CONSTRAINT [EReceivableInvoice_CancelledBy]
GO
ALTER TABLE [dbo].[ReceivableInvoices]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoices] CHECK CONSTRAINT [EReceivableInvoice_Currency]
GO
ALTER TABLE [dbo].[ReceivableInvoices]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoices] CHECK CONSTRAINT [EReceivableInvoice_Customer]
GO
ALTER TABLE [dbo].[ReceivableInvoices]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_DeliveryJobStepInstance] FOREIGN KEY([DeliveryJobStepInstanceId])
REFERENCES [dbo].[JobStepInstances] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoices] CHECK CONSTRAINT [EReceivableInvoice_DeliveryJobStepInstance]
GO
ALTER TABLE [dbo].[ReceivableInvoices]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_EmailNotification] FOREIGN KEY([EmailNotificationId])
REFERENCES [dbo].[ReceivableInvoiceEmails] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoices] CHECK CONSTRAINT [EReceivableInvoice_EmailNotification]
GO
ALTER TABLE [dbo].[ReceivableInvoices]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_JobStepInstance] FOREIGN KEY([JobStepInstanceId])
REFERENCES [dbo].[JobStepInstances] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoices] CHECK CONSTRAINT [EReceivableInvoice_JobStepInstance]
GO
ALTER TABLE [dbo].[ReceivableInvoices]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoices] CHECK CONSTRAINT [EReceivableInvoice_LegalEntity]
GO
ALTER TABLE [dbo].[ReceivableInvoices]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_ReceivableCategory] FOREIGN KEY([ReceivableCategoryId])
REFERENCES [dbo].[ReceivableCategories] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoices] CHECK CONSTRAINT [EReceivableInvoice_ReceivableCategory]
GO
ALTER TABLE [dbo].[ReceivableInvoices]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoices] CHECK CONSTRAINT [EReceivableInvoice_RemitTo]
GO
ALTER TABLE [dbo].[ReceivableInvoices]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_ReportFormat] FOREIGN KEY([ReportFormatId])
REFERENCES [dbo].[InvoiceFormats] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoices] CHECK CONSTRAINT [EReceivableInvoice_ReportFormat]
GO
