SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InvoiceExtractReceivableDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[InvoiceId] [bigint] NOT NULL,
	[ReceivableInvoiceDetailId] [bigint] NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[BlendNumber] [int] NULL,
	[ReceivableAmount_Amount] [decimal](16, 2) NULL,
	[ReceivableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxAmount_Amount] [decimal](16, 2) NULL,
	[TaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PeriodStartDate] [date] NULL,
	[PeriodEndDate] [date] NULL,
	[ReceivableCategoryId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[AssetAddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AssetAddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AssetCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetState] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[AssetDivision] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetCountry] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[AssetPostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[AssetPurchaseOrderNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetSerialNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[AssetDescription] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[u_CustomerReference1] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[u_CustomerReference2] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[u_CustomerReference3] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[u_CustomerReference4] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[u_CustomerReference5] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[EntityType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EntityId] [bigint] NULL,
	[MaturityDate] [date] NULL,
	[ContractPurchaseOrderNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AdditionalComments] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[AdditionalInvoiceCommentBeginDate] [date] NULL,
	[AdditionalInvoiceCommentEndDate] [date] NULL,
	[ExchangeRate] [decimal](20, 10) NULL,
	[AlternateBillingCurrencyCodeId] [bigint] NULL,
	[WithHoldingTax_Amount] [decimal](16, 2) NOT NULL,
	[WithHoldingTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsDownPaymentVATReceivable] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractReceivableDetail_AlternateBillingCurrencyCode] FOREIGN KEY([AlternateBillingCurrencyCodeId])
REFERENCES [dbo].[CurrencyCodes] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails] CHECK CONSTRAINT [EInvoiceExtractReceivableDetail_AlternateBillingCurrencyCode]
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractReceivableDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails] CHECK CONSTRAINT [EInvoiceExtractReceivableDetail_Asset]
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractReceivableDetail_Invoice] FOREIGN KEY([InvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails] CHECK CONSTRAINT [EInvoiceExtractReceivableDetail_Invoice]
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractReceivableDetail_ReceivableCategory] FOREIGN KEY([ReceivableCategoryId])
REFERENCES [dbo].[ReceivableCategories] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails] CHECK CONSTRAINT [EInvoiceExtractReceivableDetail_ReceivableCategory]
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractReceivableDetail_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails] CHECK CONSTRAINT [EInvoiceExtractReceivableDetail_ReceivableCode]
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractReceivableDetail_ReceivableDetail] FOREIGN KEY([ReceivableDetailId])
REFERENCES [dbo].[ReceivableDetails] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails] CHECK CONSTRAINT [EInvoiceExtractReceivableDetail_ReceivableDetail]
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractReceivableDetail_ReceivableInvoiceDetail] FOREIGN KEY([ReceivableInvoiceDetailId])
REFERENCES [dbo].[ReceivableInvoiceDetails] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableDetails] CHECK CONSTRAINT [EInvoiceExtractReceivableDetail_ReceivableInvoiceDetail]
GO
