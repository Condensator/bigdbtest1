SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BillToes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerBillToName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsPrimary] [bit] NOT NULL,
	[GenerateSummaryInvoice] [bit] NOT NULL,
	[UseLocationAddressForBilling] [bit] NOT NULL,
	[SplitRentalInvoiceByAsset] [bit] NOT NULL,
	[SplitCreditsByOriginalInvoice] [bit] NOT NULL,
	[SplitByReceivableAdjustments] [bit] NOT NULL,
	[SplitRentalInvoiceByContract] [bit] NOT NULL,
	[SplitLeaseRentalInvoiceByLocation] [bit] NOT NULL,
	[DeliverInvoiceViaEmail] [bit] NOT NULL,
	[DeliverInvoiceViaMail] [bit] NOT NULL,
	[SendEmailNotificationTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[SendCCEmailNotificationTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[SendBccEmailNotificationTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[InvoiceNumberLabel] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceDateLabel] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceCommentBeginDate] [date] NULL,
	[InvoiceCommentEndDate] [date] NULL,
	[UseDynamicContentForInvoiceBody] [bit] NOT NULL,
	[GenerateInvoiceAddendum] [bit] NOT NULL,
	[UseDynamicContentForInvoiceAddendumBody] [bit] NOT NULL,
	[AssetGroupByOption] [bit] NOT NULL,
	[IsPreACHNotification] [bit] NOT NULL,
	[PreACHNotificationEmailTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NOT NULL,
	[BillingContactPersonId] [bigint] NULL,
	[BillingAddressId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PreACHNotificationEmailTemplateId] [bigint] NULL,
	[LanguageConfigId] [bigint] NULL,
	[TaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[UpfrontTaxMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[TaxAreaVerifiedTillDate] [date] NULL,
	[TaxAreaId] [bigint] NULL,
	[JurisdictionId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[GenerateStatementInvoice] [bit] NOT NULL,
	[JurisdictionDetailId] [bigint] NULL,
	[BillToName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[StatementFrequency] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[StatementDueDay] [int] NULL,
	[StatementInvoiceFormatId] [bigint] NULL,
	[StatementInvoiceEmailTemplateId] [bigint] NULL,
	[StatementInvoiceOutputFormat] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[IsPostACHNotification] [bit] NOT NULL,
	[PostACHNotificationEmailTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[PostACHNotificationEmailTemplateId] [bigint] NULL,
	[IsReturnACHNotification] [bit] NOT NULL,
	[ReturnACHNotificationEmailTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[ReturnACHNotificationEmailTemplateId] [bigint] NULL,
	[SplitReceivableDueDate] [bit] NOT NULL,
	[SplitCustomerPurchaseOrderNumber] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BillToes]  WITH CHECK ADD  CONSTRAINT [EBillTo_BillingAddress] FOREIGN KEY([BillingAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[BillToes] CHECK CONSTRAINT [EBillTo_BillingAddress]
GO
ALTER TABLE [dbo].[BillToes]  WITH CHECK ADD  CONSTRAINT [EBillTo_BillingContactPerson] FOREIGN KEY([BillingContactPersonId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[BillToes] CHECK CONSTRAINT [EBillTo_BillingContactPerson]
GO
ALTER TABLE [dbo].[BillToes]  WITH CHECK ADD  CONSTRAINT [EBillTo_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[BillToes] CHECK CONSTRAINT [EBillTo_Customer]
GO
ALTER TABLE [dbo].[BillToes]  WITH CHECK ADD  CONSTRAINT [EBillTo_Jurisdiction] FOREIGN KEY([JurisdictionId])
REFERENCES [dbo].[Jurisdictions] ([Id])
GO
ALTER TABLE [dbo].[BillToes] CHECK CONSTRAINT [EBillTo_Jurisdiction]
GO
ALTER TABLE [dbo].[BillToes]  WITH CHECK ADD  CONSTRAINT [EBillTo_JurisdictionDetail] FOREIGN KEY([JurisdictionDetailId])
REFERENCES [dbo].[JurisdictionDetails] ([Id])
GO
ALTER TABLE [dbo].[BillToes] CHECK CONSTRAINT [EBillTo_JurisdictionDetail]
GO
ALTER TABLE [dbo].[BillToes]  WITH CHECK ADD  CONSTRAINT [EBillTo_LanguageConfig] FOREIGN KEY([LanguageConfigId])
REFERENCES [dbo].[LanguageConfigs] ([Id])
GO
ALTER TABLE [dbo].[BillToes] CHECK CONSTRAINT [EBillTo_LanguageConfig]
GO
ALTER TABLE [dbo].[BillToes]  WITH CHECK ADD  CONSTRAINT [EBillTo_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[BillToes] CHECK CONSTRAINT [EBillTo_Location]
GO
ALTER TABLE [dbo].[BillToes]  WITH CHECK ADD  CONSTRAINT [EBillTo_PostACHNotificationEmailTemplate] FOREIGN KEY([PostACHNotificationEmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[BillToes] CHECK CONSTRAINT [EBillTo_PostACHNotificationEmailTemplate]
GO
ALTER TABLE [dbo].[BillToes]  WITH CHECK ADD  CONSTRAINT [EBillTo_PreACHNotificationEmailTemplate] FOREIGN KEY([PreACHNotificationEmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[BillToes] CHECK CONSTRAINT [EBillTo_PreACHNotificationEmailTemplate]
GO
ALTER TABLE [dbo].[BillToes]  WITH CHECK ADD  CONSTRAINT [EBillTo_ReturnACHNotificationEmailTemplate] FOREIGN KEY([ReturnACHNotificationEmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[BillToes] CHECK CONSTRAINT [EBillTo_ReturnACHNotificationEmailTemplate]
GO
ALTER TABLE [dbo].[BillToes]  WITH CHECK ADD  CONSTRAINT [EBillTo_StatementInvoiceEmailTemplate] FOREIGN KEY([StatementInvoiceEmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[BillToes] CHECK CONSTRAINT [EBillTo_StatementInvoiceEmailTemplate]
GO
ALTER TABLE [dbo].[BillToes]  WITH CHECK ADD  CONSTRAINT [EBillTo_StatementInvoiceFormat] FOREIGN KEY([StatementInvoiceFormatId])
REFERENCES [dbo].[InvoiceFormats] ([Id])
GO
ALTER TABLE [dbo].[BillToes] CHECK CONSTRAINT [EBillTo_StatementInvoiceFormat]
GO
