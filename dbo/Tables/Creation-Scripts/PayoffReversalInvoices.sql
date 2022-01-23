SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayoffReversalInvoices](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReferenceNumber] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[InvoiceFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFile_Content] [varbinary](82) NULL,
	[InvoiceId] [bigint] NULL,
	[PayoffReversalId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[PayoffReversalInvoices]  WITH CHECK ADD  CONSTRAINT [EPayoffReversal_PayoffReversalInvoices] FOREIGN KEY([PayoffReversalId])
REFERENCES [dbo].[PayoffReversals] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayoffReversalInvoices] CHECK CONSTRAINT [EPayoffReversal_PayoffReversalInvoices]
GO
ALTER TABLE [dbo].[PayoffReversalInvoices]  WITH CHECK ADD  CONSTRAINT [EPayoffReversalInvoice_Invoice] FOREIGN KEY([InvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[PayoffReversalInvoices] CHECK CONSTRAINT [EPayoffReversalInvoice_Invoice]
GO
