SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BillToInvoiceBodyDynamicContents](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IncludeInInvoice] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InvoiceBodyDynamicContentId] [bigint] NOT NULL,
	[BillToId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BillToInvoiceBodyDynamicContents]  WITH CHECK ADD  CONSTRAINT [EBillTo_BillToInvoiceBodyDynamicContents] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[BillToInvoiceBodyDynamicContents] CHECK CONSTRAINT [EBillTo_BillToInvoiceBodyDynamicContents]
GO
ALTER TABLE [dbo].[BillToInvoiceBodyDynamicContents]  WITH CHECK ADD  CONSTRAINT [EBillToInvoiceBodyDynamicContent_InvoiceBodyDynamicContent] FOREIGN KEY([InvoiceBodyDynamicContentId])
REFERENCES [dbo].[InvoiceBodyDynamicContents] ([Id])
GO
ALTER TABLE [dbo].[BillToInvoiceBodyDynamicContents] CHECK CONSTRAINT [EBillToInvoiceBodyDynamicContent_InvoiceBodyDynamicContent]
GO
