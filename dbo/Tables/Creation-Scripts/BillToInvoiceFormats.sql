SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BillToInvoiceFormats](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableCategory] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceOutputFormat] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InvoiceFormatId] [bigint] NOT NULL,
	[InvoiceTypeLabelId] [bigint] NOT NULL,
	[BillToId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[InvoiceEmailTemplateId] [bigint] NULL,
	[ReceivableCategoryId] [bigint] NULL,
	[VATInvoiceFormatId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BillToInvoiceFormats]  WITH CHECK ADD  CONSTRAINT [EBillTo_BillToInvoiceFormats] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[BillToInvoiceFormats] CHECK CONSTRAINT [EBillTo_BillToInvoiceFormats]
GO
ALTER TABLE [dbo].[BillToInvoiceFormats]  WITH CHECK ADD  CONSTRAINT [EBillToInvoiceFormat_InvoiceEmailTemplate] FOREIGN KEY([InvoiceEmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[BillToInvoiceFormats] CHECK CONSTRAINT [EBillToInvoiceFormat_InvoiceEmailTemplate]
GO
ALTER TABLE [dbo].[BillToInvoiceFormats]  WITH CHECK ADD  CONSTRAINT [EBillToInvoiceFormat_InvoiceFormat] FOREIGN KEY([InvoiceFormatId])
REFERENCES [dbo].[InvoiceFormats] ([Id])
GO
ALTER TABLE [dbo].[BillToInvoiceFormats] CHECK CONSTRAINT [EBillToInvoiceFormat_InvoiceFormat]
GO
ALTER TABLE [dbo].[BillToInvoiceFormats]  WITH CHECK ADD  CONSTRAINT [EBillToInvoiceFormat_InvoiceTypeLabel] FOREIGN KEY([InvoiceTypeLabelId])
REFERENCES [dbo].[InvoiceTypeLabelConfigs] ([Id])
GO
ALTER TABLE [dbo].[BillToInvoiceFormats] CHECK CONSTRAINT [EBillToInvoiceFormat_InvoiceTypeLabel]
GO
ALTER TABLE [dbo].[BillToInvoiceFormats]  WITH CHECK ADD  CONSTRAINT [EBillToInvoiceFormat_VATInvoiceFormat] FOREIGN KEY([VATInvoiceFormatId])
REFERENCES [dbo].[InvoiceFormats] ([Id])
GO
ALTER TABLE [dbo].[BillToInvoiceFormats] CHECK CONSTRAINT [EBillToInvoiceFormat_VATInvoiceFormat]
GO
