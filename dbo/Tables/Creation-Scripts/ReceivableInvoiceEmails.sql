SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableInvoiceEmails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SentDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EmailTemplateId] [bigint] NULL,
	[SentByUserId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableInvoiceEmails]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoiceEmail_EmailTemplate] FOREIGN KEY([EmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoiceEmails] CHECK CONSTRAINT [EReceivableInvoiceEmail_EmailTemplate]
GO
ALTER TABLE [dbo].[ReceivableInvoiceEmails]  WITH CHECK ADD  CONSTRAINT [EReceivableInvoiceEmail_SentByUser] FOREIGN KEY([SentByUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[ReceivableInvoiceEmails] CHECK CONSTRAINT [EReceivableInvoiceEmail_SentByUser]
GO
