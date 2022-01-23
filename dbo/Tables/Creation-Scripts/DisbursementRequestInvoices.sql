SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DisbursementRequestInvoices](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmountToPay_Amount] [decimal](16, 2) NOT NULL,
	[AmountToPay_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InvoiceId] [bigint] NOT NULL,
	[DisbursementRequestId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DisbursementRequestInvoices]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_DisbursementRequestInvoices] FOREIGN KEY([DisbursementRequestId])
REFERENCES [dbo].[DisbursementRequests] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DisbursementRequestInvoices] CHECK CONSTRAINT [EDisbursementRequest_DisbursementRequestInvoices]
GO
ALTER TABLE [dbo].[DisbursementRequestInvoices]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequestInvoice_Invoice] FOREIGN KEY([InvoiceId])
REFERENCES [dbo].[PayableInvoices] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequestInvoices] CHECK CONSTRAINT [EDisbursementRequestInvoice_Invoice]
GO
