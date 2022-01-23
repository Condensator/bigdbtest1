SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InvoiceGroupingParameters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[InvoiceGroupingCategory] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[AllowBlending] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[IsSystemDefined] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[ReceivableCategoryId] [bigint] NOT NULL,
	[BlendReceivableCategoryId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsParent] [bit] NOT NULL,
	[Blending] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[BlendWithReceivableTypeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InvoiceGroupingParameters]  WITH CHECK ADD  CONSTRAINT [EInvoiceGroupingParameter_BlendReceivableCategory] FOREIGN KEY([BlendReceivableCategoryId])
REFERENCES [dbo].[ReceivableCategories] ([Id])
GO
ALTER TABLE [dbo].[InvoiceGroupingParameters] CHECK CONSTRAINT [EInvoiceGroupingParameter_BlendReceivableCategory]
GO
ALTER TABLE [dbo].[InvoiceGroupingParameters]  WITH CHECK ADD  CONSTRAINT [EInvoiceGroupingParameter_BlendWithReceivableType] FOREIGN KEY([BlendWithReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[InvoiceGroupingParameters] CHECK CONSTRAINT [EInvoiceGroupingParameter_BlendWithReceivableType]
GO
ALTER TABLE [dbo].[InvoiceGroupingParameters]  WITH CHECK ADD  CONSTRAINT [EInvoiceGroupingParameter_ReceivableCategory] FOREIGN KEY([ReceivableCategoryId])
REFERENCES [dbo].[ReceivableCategories] ([Id])
GO
ALTER TABLE [dbo].[InvoiceGroupingParameters] CHECK CONSTRAINT [EInvoiceGroupingParameter_ReceivableCategory]
GO
ALTER TABLE [dbo].[InvoiceGroupingParameters]  WITH CHECK ADD  CONSTRAINT [EInvoiceGroupingParameter_ReceivableType] FOREIGN KEY([ReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[InvoiceGroupingParameters] CHECK CONSTRAINT [EInvoiceGroupingParameter_ReceivableType]
GO
