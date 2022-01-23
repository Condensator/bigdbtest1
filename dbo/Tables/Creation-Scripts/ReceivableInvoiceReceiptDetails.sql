SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableInvoiceReceiptDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivedDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[AmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxApplied_Amount] [decimal](16, 2) NOT NULL,
	[TaxApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptId] [bigint] NOT NULL,
	[ReceivableInvoiceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableInvoiceReceiptDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoice_ReceivableInvoiceReceiptDetails] FOREIGN KEY([ReceivableInvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableInvoiceReceiptDetails] CHECK CONSTRAINT [EReceivableInvoice_ReceivableInvoiceReceiptDetails]
GO
ALTER TABLE [dbo].[ReceivableInvoiceReceiptDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoiceReceiptDetail_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoiceReceiptDetails] CHECK CONSTRAINT [EReceivableInvoiceReceiptDetail_Receipt]
GO
