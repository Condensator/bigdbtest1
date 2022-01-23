SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OneTimeACHRequestInvoices](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PaymentDate] [date] NULL,
	[AmountToPay_Amount] [decimal](16, 2) NOT NULL,
	[AmountToPay_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivableInvoiceId] [bigint] NOT NULL,
	[OneTimeACHRequestId] [bigint] NOT NULL,
	[OneTimeACHId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsStatementInvoice] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[OneTimeACHRequestInvoices]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHRequest_OneTimeACHRequestInvoices] FOREIGN KEY([OneTimeACHRequestId])
REFERENCES [dbo].[OneTimeACHRequests] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[OneTimeACHRequestInvoices] CHECK CONSTRAINT [EOneTimeACHRequest_OneTimeACHRequestInvoices]
GO
ALTER TABLE [dbo].[OneTimeACHRequestInvoices]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHRequestInvoice_OneTimeACH] FOREIGN KEY([OneTimeACHId])
REFERENCES [dbo].[OneTimeACHes] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHRequestInvoices] CHECK CONSTRAINT [EOneTimeACHRequestInvoice_OneTimeACH]
GO
ALTER TABLE [dbo].[OneTimeACHRequestInvoices]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHRequestInvoice_ReceivableInvoice] FOREIGN KEY([ReceivableInvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHRequestInvoices] CHECK CONSTRAINT [EOneTimeACHRequestInvoice_ReceivableInvoice]
GO
