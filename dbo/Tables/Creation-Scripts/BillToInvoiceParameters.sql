SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BillToInvoiceParameters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InvoiceGroupingParameterId] [bigint] NOT NULL,
	[ReceivableTypeLabelId] [bigint] NULL,
	[BillToId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ReceivableTypeLanguageLabelId] [bigint] NULL,
	[AllowBlending] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BlendWithReceivableTypeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BillToInvoiceParameters]  WITH CHECK ADD  CONSTRAINT [EBillTo_BillToInvoiceParameters] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[BillToInvoiceParameters] CHECK CONSTRAINT [EBillTo_BillToInvoiceParameters]
GO
ALTER TABLE [dbo].[BillToInvoiceParameters]  WITH CHECK ADD  CONSTRAINT [EBillToInvoiceParameter_BlendWithReceivableType] FOREIGN KEY([BlendWithReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[BillToInvoiceParameters] CHECK CONSTRAINT [EBillToInvoiceParameter_BlendWithReceivableType]
GO
ALTER TABLE [dbo].[BillToInvoiceParameters]  WITH CHECK ADD  CONSTRAINT [EBillToInvoiceParameter_InvoiceGroupingParameter] FOREIGN KEY([InvoiceGroupingParameterId])
REFERENCES [dbo].[InvoiceGroupingParameters] ([Id])
GO
ALTER TABLE [dbo].[BillToInvoiceParameters] CHECK CONSTRAINT [EBillToInvoiceParameter_InvoiceGroupingParameter]
GO
ALTER TABLE [dbo].[BillToInvoiceParameters]  WITH CHECK ADD  CONSTRAINT [EBillToInvoiceParameter_ReceivableTypeLabel] FOREIGN KEY([ReceivableTypeLabelId])
REFERENCES [dbo].[ReceivableTypeLabelConfigs] ([Id])
GO
ALTER TABLE [dbo].[BillToInvoiceParameters] CHECK CONSTRAINT [EBillToInvoiceParameter_ReceivableTypeLabel]
GO
ALTER TABLE [dbo].[BillToInvoiceParameters]  WITH CHECK ADD  CONSTRAINT [EBillToInvoiceParameter_ReceivableTypeLanguageLabel] FOREIGN KEY([ReceivableTypeLanguageLabelId])
REFERENCES [dbo].[ReceivableTypeLanguageLabels] ([Id])
GO
ALTER TABLE [dbo].[BillToInvoiceParameters] CHECK CONSTRAINT [EBillToInvoiceParameter_ReceivableTypeLanguageLabel]
GO
