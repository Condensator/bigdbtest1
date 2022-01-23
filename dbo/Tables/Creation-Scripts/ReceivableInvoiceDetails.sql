SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableInvoiceDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](2) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityId] [bigint] NOT NULL,
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
	[BlendNumber] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[ReceivableInvoiceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ExchangeRate] [decimal](20, 10) NULL,
	[ReceivableCategoryId] [bigint] NOT NULL,
	[ReceivableAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceivableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PaymentType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableInvoiceDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_ReceivableInvoiceDetails] FOREIGN KEY([ReceivableInvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableInvoiceDetails] CHECK CONSTRAINT [EReceivableInvoice_ReceivableInvoiceDetails]
GO
ALTER TABLE [dbo].[ReceivableInvoiceDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoiceDetail_ReceivableCategory] FOREIGN KEY([ReceivableCategoryId])
REFERENCES [dbo].[ReceivableCategories] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoiceDetails] CHECK CONSTRAINT [EReceivableInvoiceDetail_ReceivableCategory]
GO
ALTER TABLE [dbo].[ReceivableInvoiceDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoiceDetail_ReceivableDetail] FOREIGN KEY([ReceivableDetailId])
REFERENCES [dbo].[ReceivableDetails] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoiceDetails] CHECK CONSTRAINT [EReceivableInvoiceDetail_ReceivableDetail]
GO
