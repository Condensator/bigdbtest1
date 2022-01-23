SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OneTimeACHInvoices](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivableInvoiceId] [bigint] NOT NULL,
	[OneTimeACHId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsStatementInvoice] [bit] NOT NULL,
	[Status] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmountApplied_Amount] [decimal](16, 2) NULL,
	[AmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[OneTimeACHInvoices]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_OneTimeACHInvoices] FOREIGN KEY([OneTimeACHId])
REFERENCES [dbo].[OneTimeACHes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[OneTimeACHInvoices] CHECK CONSTRAINT [EOneTimeACH_OneTimeACHInvoices]
GO
ALTER TABLE [dbo].[OneTimeACHInvoices]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHInvoice_ReceivableInvoice] FOREIGN KEY([ReceivableInvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHInvoices] CHECK CONSTRAINT [EOneTimeACHInvoice_ReceivableInvoice]
GO
