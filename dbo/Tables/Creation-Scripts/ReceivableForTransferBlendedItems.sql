SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableForTransferBlendedItems](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FundingSourceId] [bigint] NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[ReceivableForTransferId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableForTransferBlendedItems]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_ReceivableForTransferBlendedItems] FOREIGN KEY([ReceivableForTransferId])
REFERENCES [dbo].[ReceivableForTransfers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableForTransferBlendedItems] CHECK CONSTRAINT [EReceivableForTransfer_ReceivableForTransferBlendedItems]
GO
ALTER TABLE [dbo].[ReceivableForTransferBlendedItems]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransferBlendedItem_BlendedItem] FOREIGN KEY([BlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransferBlendedItems] CHECK CONSTRAINT [EReceivableForTransferBlendedItem_BlendedItem]
GO
ALTER TABLE [dbo].[ReceivableForTransferBlendedItems]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransferBlendedItem_FundingSource] FOREIGN KEY([FundingSourceId])
REFERENCES [dbo].[ReceivableForTransferFundingSources] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransferBlendedItems] CHECK CONSTRAINT [EReceivableForTransferBlendedItem_FundingSource]
GO
