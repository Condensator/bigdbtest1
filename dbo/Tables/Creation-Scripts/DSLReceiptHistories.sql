SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DSLReceiptHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[InvoiceId] [bigint] NULL,
	[AmountPosted_Amount] [decimal](16, 2) NULL,
	[AmountPosted_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ReceivedDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivableDetailId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DSLReceiptHistories]  WITH CHECK ADD  CONSTRAINT [EDSLReceiptHistory_Invoice] FOREIGN KEY([InvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[DSLReceiptHistories] CHECK CONSTRAINT [EDSLReceiptHistory_Invoice]
GO
ALTER TABLE [dbo].[DSLReceiptHistories]  WITH CHECK ADD  CONSTRAINT [EDSLReceiptHistory_ReceivableDetail] FOREIGN KEY([ReceivableDetailId])
REFERENCES [dbo].[ReceivableDetails] ([Id])
GO
ALTER TABLE [dbo].[DSLReceiptHistories] CHECK CONSTRAINT [EDSLReceiptHistory_ReceivableDetail]
GO
ALTER TABLE [dbo].[DSLReceiptHistories]  WITH CHECK ADD  CONSTRAINT [EReceipt_DSLReceiptHistories] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DSLReceiptHistories] CHECK CONSTRAINT [EReceipt_DSLReceiptHistories]
GO
