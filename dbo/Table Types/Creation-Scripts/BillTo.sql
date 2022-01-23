CREATE TYPE [dbo].[BillTo] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BillToName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
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
	[SplitReceivableDueDate] [bit] NOT NULL,
	[SplitCustomerPurchaseOrderNumber] [bit] NOT NULL,
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
	[IsPostACHNotification] [bit] NOT NULL,
	[PostACHNotificationEmailTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsReturnACHNotification] [bit] NOT NULL,
	[ReturnACHNotificationEmailTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[TaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[UpfrontTaxMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[TaxAreaId] [bigint] NULL,
	[TaxAreaVerifiedTillDate] [date] NULL,
	[GenerateStatementInvoice] [bit] NOT NULL,
	[StatementFrequency] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[StatementDueDay] [int] NULL,
	[StatementInvoiceOutputFormat] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[CustomerId] [bigint] NOT NULL,
	[BillingContactPersonId] [bigint] NULL,
	[BillingAddressId] [bigint] NOT NULL,
	[PreACHNotificationEmailTemplateId] [bigint] NULL,
	[PostACHNotificationEmailTemplateId] [bigint] NULL,
	[ReturnACHNotificationEmailTemplateId] [bigint] NULL,
	[LanguageConfigId] [bigint] NULL,
	[JurisdictionId] [bigint] NULL,
	[JurisdictionDetailId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[StatementInvoiceFormatId] [bigint] NULL,
	[StatementInvoiceEmailTemplateId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
