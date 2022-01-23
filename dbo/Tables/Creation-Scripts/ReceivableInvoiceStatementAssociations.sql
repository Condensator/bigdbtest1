SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableInvoiceStatementAssociations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[StatementInvoiceId] [bigint] NOT NULL,
	[ReceivableInvoiceId] [bigint] NOT NULL,
	[IsCurrentInvoice] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableInvoiceStatementAssociations]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoiceStatementAssociation_ReceivableInvoice] FOREIGN KEY([ReceivableInvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoiceStatementAssociations] CHECK CONSTRAINT [EReceivableInvoiceStatementAssociation_ReceivableInvoice]
GO
ALTER TABLE [dbo].[ReceivableInvoiceStatementAssociations]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoiceStatementAssociation_StatementInvoice] FOREIGN KEY([StatementInvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoiceStatementAssociations] CHECK CONSTRAINT [EReceivableInvoiceStatementAssociation_StatementInvoice]
GO
