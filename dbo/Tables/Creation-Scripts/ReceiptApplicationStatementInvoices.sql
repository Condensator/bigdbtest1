SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptApplicationStatementInvoices](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StatementInvoiceId] [bigint] NOT NULL,
	[ReceiptApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptApplicationStatementInvoices]  WITH CHECK ADD  CONSTRAINT [EReceiptApplication_ReceiptApplicationStatementInvoices] FOREIGN KEY([ReceiptApplicationId])
REFERENCES [dbo].[ReceiptApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceiptApplicationStatementInvoices] CHECK CONSTRAINT [EReceiptApplication_ReceiptApplicationStatementInvoices]
GO
ALTER TABLE [dbo].[ReceiptApplicationStatementInvoices]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationStatementInvoice_StatementInvoice] FOREIGN KEY([StatementInvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationStatementInvoices] CHECK CONSTRAINT [EReceiptApplicationStatementInvoice_StatementInvoice]
GO
