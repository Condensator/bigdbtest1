SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SKUs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Quantity] [int] NOT NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ManufacturerId] [bigint] NULL,
	[MakeId] [bigint] NULL,
	[ModelId] [bigint] NULL,
	[TypeId] [bigint] NOT NULL,
	[AssetCatalogId] [bigint] NULL,
	[AssetCategoryId] [bigint] NULL,
	[ProductId] [bigint] NULL,
	[SKUSetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsSalesTaxExempt] [bit] NOT NULL,
	[PricingGroupId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SKUs]  WITH CHECK ADD  CONSTRAINT [ESKU_AssetCatalog] FOREIGN KEY([AssetCatalogId])
REFERENCES [dbo].[AssetCatalogs] ([Id])
GO
ALTER TABLE [dbo].[SKUs] CHECK CONSTRAINT [ESKU_AssetCatalog]
GO
ALTER TABLE [dbo].[SKUs]  WITH CHECK ADD  CONSTRAINT [ESKU_AssetCategory] FOREIGN KEY([AssetCategoryId])
REFERENCES [dbo].[AssetCategories] ([Id])
GO
ALTER TABLE [dbo].[SKUs] CHECK CONSTRAINT [ESKU_AssetCategory]
GO
ALTER TABLE [dbo].[SKUs]  WITH CHECK ADD  CONSTRAINT [ESKU_Make] FOREIGN KEY([MakeId])
REFERENCES [dbo].[Makes] ([Id])
GO
ALTER TABLE [dbo].[SKUs] CHECK CONSTRAINT [ESKU_Make]
GO
ALTER TABLE [dbo].[SKUs]  WITH CHECK ADD  CONSTRAINT [ESKU_Manufacturer] FOREIGN KEY([ManufacturerId])
REFERENCES [dbo].[Manufacturers] ([Id])
GO
ALTER TABLE [dbo].[SKUs] CHECK CONSTRAINT [ESKU_Manufacturer]
GO
ALTER TABLE [dbo].[SKUs]  WITH CHECK ADD  CONSTRAINT [ESKU_Model] FOREIGN KEY([ModelId])
REFERENCES [dbo].[Models] ([Id])
GO
ALTER TABLE [dbo].[SKUs] CHECK CONSTRAINT [ESKU_Model]
GO
ALTER TABLE [dbo].[SKUs]  WITH CHECK ADD  CONSTRAINT [ESKU_PricingGroup] FOREIGN KEY([PricingGroupId])
REFERENCES [dbo].[PricingGroups] ([Id])
GO
ALTER TABLE [dbo].[SKUs] CHECK CONSTRAINT [ESKU_PricingGroup]
GO
ALTER TABLE [dbo].[SKUs]  WITH CHECK ADD  CONSTRAINT [ESKU_Product] FOREIGN KEY([ProductId])
REFERENCES [dbo].[Products] ([Id])
GO
ALTER TABLE [dbo].[SKUs] CHECK CONSTRAINT [ESKU_Product]
GO
ALTER TABLE [dbo].[SKUs]  WITH CHECK ADD  CONSTRAINT [ESKU_Type] FOREIGN KEY([TypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[SKUs] CHECK CONSTRAINT [ESKU_Type]
GO
ALTER TABLE [dbo].[SKUs]  WITH CHECK ADD  CONSTRAINT [ESKUSet_SKUs] FOREIGN KEY([SKUSetId])
REFERENCES [dbo].[SKUSets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SKUs] CHECK CONSTRAINT [ESKUSet_SKUs]
GO
