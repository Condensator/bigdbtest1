SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OneTimeACHStatementInvoiceAssociations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableInvoiceId] [bigint] NOT NULL,
	[OneTimeACHInvoiceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[OneTimeACHStatementInvoiceAssociations]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHInvoice_OneTimeACHStatementInvoiceAssociations] FOREIGN KEY([OneTimeACHInvoiceId])
REFERENCES [dbo].[OneTimeACHInvoices] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[OneTimeACHStatementInvoiceAssociations] CHECK CONSTRAINT [EOneTimeACHInvoice_OneTimeACHStatementInvoiceAssociations]
GO
ALTER TABLE [dbo].[OneTimeACHStatementInvoiceAssociations]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHStatementInvoiceAssociation_ReceivableInvoice] FOREIGN KEY([ReceivableInvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHStatementInvoiceAssociations] CHECK CONSTRAINT [EOneTimeACHStatementInvoiceAssociation_ReceivableInvoice]
GO
