SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptPostingOrders](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Order] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[ReceiptHierarchyTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptPostingOrders]  WITH CHECK ADD  CONSTRAINT [EReceiptHierarchyTemplate_ReceiptPostingOrders] FOREIGN KEY([ReceiptHierarchyTemplateId])
REFERENCES [dbo].[ReceiptHierarchyTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceiptPostingOrders] CHECK CONSTRAINT [EReceiptHierarchyTemplate_ReceiptPostingOrders]
GO
ALTER TABLE [dbo].[ReceiptPostingOrders]  WITH CHECK ADD  CONSTRAINT [EReceiptPostingOrder_ReceivableType] FOREIGN KEY([ReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[ReceiptPostingOrders] CHECK CONSTRAINT [EReceiptPostingOrder_ReceivableType]
GO
