SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InvoiceExtractReceivableTaxDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[InvoiceId] [bigint] NOT NULL,
	[TaxTypeId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[ReceivableTaxDetailId] [bigint] NOT NULL,
	[AssetId] [bigint] NULL,
	[Rent_Amount] [decimal](16, 2) NULL,
	[Rent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxAmount_Amount] [decimal](16, 2) NULL,
	[TaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ExternalJurisdictionId] [int] NULL,
	[ImpositionType] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableCodeId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxCodeId] [bigint] NULL,
	[TaxRate] [decimal](10, 6) NULL,
	[TaxTreatment] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InvoiceExtractReceivableTaxDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractReceivableTaxDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableTaxDetails] CHECK CONSTRAINT [EInvoiceExtractReceivableTaxDetail_Asset]
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableTaxDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractReceivableTaxDetail_Invoice] FOREIGN KEY([InvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableTaxDetails] CHECK CONSTRAINT [EInvoiceExtractReceivableTaxDetail_Invoice]
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableTaxDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractReceivableTaxDetail_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableTaxDetails] CHECK CONSTRAINT [EInvoiceExtractReceivableTaxDetail_ReceivableCode]
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableTaxDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractReceivableTaxDetail_ReceivableDetail] FOREIGN KEY([ReceivableDetailId])
REFERENCES [dbo].[ReceivableDetails] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableTaxDetails] CHECK CONSTRAINT [EInvoiceExtractReceivableTaxDetail_ReceivableDetail]
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableTaxDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractReceivableTaxDetail_ReceivableTaxDetail] FOREIGN KEY([ReceivableTaxDetailId])
REFERENCES [dbo].[ReceivableTaxDetails] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableTaxDetails] CHECK CONSTRAINT [EInvoiceExtractReceivableTaxDetail_ReceivableTaxDetail]
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableTaxDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractReceivableTaxDetail_TaxType] FOREIGN KEY([TaxTypeId])
REFERENCES [dbo].[TaxTypes] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractReceivableTaxDetails] CHECK CONSTRAINT [EInvoiceExtractReceivableTaxDetail_TaxType]
GO
