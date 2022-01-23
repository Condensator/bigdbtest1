SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetSaleBlendedItems](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[AssetSaleId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AssetId] [bigint] NULL,
	[SundryId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetSaleBlendedItems]  WITH CHECK ADD  CONSTRAINT [EAssetSale_AssetSaleBlendedItems] FOREIGN KEY([AssetSaleId])
REFERENCES [dbo].[AssetSales] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetSaleBlendedItems] CHECK CONSTRAINT [EAssetSale_AssetSaleBlendedItems]
GO
ALTER TABLE [dbo].[AssetSaleBlendedItems]  WITH CHECK ADD  CONSTRAINT [EAssetSaleBlendedItem_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetSaleBlendedItems] CHECK CONSTRAINT [EAssetSaleBlendedItem_Asset]
GO
ALTER TABLE [dbo].[AssetSaleBlendedItems]  WITH CHECK ADD  CONSTRAINT [EAssetSaleBlendedItem_BlendedItem] FOREIGN KEY([BlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
GO
ALTER TABLE [dbo].[AssetSaleBlendedItems] CHECK CONSTRAINT [EAssetSaleBlendedItem_BlendedItem]
GO
ALTER TABLE [dbo].[AssetSaleBlendedItems]  WITH CHECK ADD  CONSTRAINT [EAssetSaleBlendedItem_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[AssetSaleBlendedItems] CHECK CONSTRAINT [EAssetSaleBlendedItem_GLJournal]
GO
ALTER TABLE [dbo].[AssetSaleBlendedItems]  WITH CHECK ADD  CONSTRAINT [EAssetSaleBlendedItem_Sundry] FOREIGN KEY([SundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[AssetSaleBlendedItems] CHECK CONSTRAINT [EAssetSaleBlendedItem_Sundry]
GO
