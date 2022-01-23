SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetSKUs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SerialNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[IsLeaseComponent] [bit] NOT NULL,
	[Quantity] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ManufacturerId] [bigint] NULL,
	[MakeId] [bigint] NULL,
	[ModelId] [bigint] NULL,
	[TypeId] [bigint] NOT NULL,
	[AssetCatalogId] [bigint] NULL,
	[AssetCategoryId] [bigint] NULL,
	[ProductId] [bigint] NULL,
	[AssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsSalesTaxExempt] [bit] NOT NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[PricingGroupId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetSKUs]  WITH NOCHECK ADD  CONSTRAINT [EAsset_AssetSKUs] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetSKUs] NOCHECK CONSTRAINT [EAsset_AssetSKUs]
GO
ALTER TABLE [dbo].[AssetSKUs]  WITH CHECK ADD  CONSTRAINT [EAssetSKU_AssetCatalog] FOREIGN KEY([AssetCatalogId])
REFERENCES [dbo].[AssetCatalogs] ([Id])
GO
ALTER TABLE [dbo].[AssetSKUs] CHECK CONSTRAINT [EAssetSKU_AssetCatalog]
GO
ALTER TABLE [dbo].[AssetSKUs]  WITH CHECK ADD  CONSTRAINT [EAssetSKU_AssetCategory] FOREIGN KEY([AssetCategoryId])
REFERENCES [dbo].[AssetCategories] ([Id])
GO
ALTER TABLE [dbo].[AssetSKUs] CHECK CONSTRAINT [EAssetSKU_AssetCategory]
GO
ALTER TABLE [dbo].[AssetSKUs]  WITH CHECK ADD  CONSTRAINT [EAssetSKU_Make] FOREIGN KEY([MakeId])
REFERENCES [dbo].[Makes] ([Id])
GO
ALTER TABLE [dbo].[AssetSKUs] CHECK CONSTRAINT [EAssetSKU_Make]
GO
ALTER TABLE [dbo].[AssetSKUs]  WITH CHECK ADD  CONSTRAINT [EAssetSKU_Manufacturer] FOREIGN KEY([ManufacturerId])
REFERENCES [dbo].[Manufacturers] ([Id])
GO
ALTER TABLE [dbo].[AssetSKUs] CHECK CONSTRAINT [EAssetSKU_Manufacturer]
GO
ALTER TABLE [dbo].[AssetSKUs]  WITH CHECK ADD  CONSTRAINT [EAssetSKU_Model] FOREIGN KEY([ModelId])
REFERENCES [dbo].[Models] ([Id])
GO
ALTER TABLE [dbo].[AssetSKUs] CHECK CONSTRAINT [EAssetSKU_Model]
GO
ALTER TABLE [dbo].[AssetSKUs]  WITH CHECK ADD  CONSTRAINT [EAssetSKU_PricingGroup] FOREIGN KEY([PricingGroupId])
REFERENCES [dbo].[PricingGroups] ([Id])
GO
ALTER TABLE [dbo].[AssetSKUs] CHECK CONSTRAINT [EAssetSKU_PricingGroup]
GO
ALTER TABLE [dbo].[AssetSKUs]  WITH CHECK ADD  CONSTRAINT [EAssetSKU_Product] FOREIGN KEY([ProductId])
REFERENCES [dbo].[Products] ([Id])
GO
ALTER TABLE [dbo].[AssetSKUs] CHECK CONSTRAINT [EAssetSKU_Product]
GO
ALTER TABLE [dbo].[AssetSKUs]  WITH CHECK ADD  CONSTRAINT [EAssetSKU_Type] FOREIGN KEY([TypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetSKUs] CHECK CONSTRAINT [EAssetSKU_Type]
GO
