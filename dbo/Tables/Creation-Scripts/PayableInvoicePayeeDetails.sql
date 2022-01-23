SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayableInvoicePayeeDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[IsPrimaryPayee] [bit] NOT NULL,
	[PayeeId] [bigint] NOT NULL,
	[RemitToId] [bigint] NULL,
	[PayableInvoiceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayableInvoicePayeeDetails]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_PayableInvoicePayeeDetails] FOREIGN KEY([PayableInvoiceId])
REFERENCES [dbo].[PayableInvoices] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayableInvoicePayeeDetails] CHECK CONSTRAINT [EPayableInvoice_PayableInvoicePayeeDetails]
GO
ALTER TABLE [dbo].[PayableInvoicePayeeDetails]  WITH CHECK ADD  CONSTRAINT [EPayableInvoicePayeeDetail_Payee] FOREIGN KEY([PayeeId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoicePayeeDetails] CHECK CONSTRAINT [EPayableInvoicePayeeDetail_Payee]
GO
ALTER TABLE [dbo].[PayableInvoicePayeeDetails]  WITH CHECK ADD  CONSTRAINT [EPayableInvoicePayeeDetail_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoicePayeeDetails] CHECK CONSTRAINT [EPayableInvoicePayeeDetail_RemitTo]
GO
