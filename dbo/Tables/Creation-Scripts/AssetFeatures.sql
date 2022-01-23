SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetFeatures](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Alias] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[Quantity] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ManufacturerId] [bigint] NULL,
	[TypeId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[StateId] [bigint] NULL,
	[AssetCatalogID] [bigint] NULL,
	[AssetCategoryID] [bigint] NULL,
	[ProductID] [bigint] NULL,
	[MakeId] [bigint] NULL,
	[ModelId] [bigint] NULL,
	[Value_Amount] [decimal](16, 2) NOT NULL,
	[Value_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetFeatures]  WITH CHECK ADD  CONSTRAINT [EAsset_AssetFeatures] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetFeatures] CHECK CONSTRAINT [EAsset_AssetFeatures]
GO
ALTER TABLE [dbo].[AssetFeatures]  WITH CHECK ADD  CONSTRAINT [EAssetFeature_AssetCatalog] FOREIGN KEY([AssetCatalogID])
REFERENCES [dbo].[AssetCatalogs] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatures] CHECK CONSTRAINT [EAssetFeature_AssetCatalog]
GO
ALTER TABLE [dbo].[AssetFeatures]  WITH CHECK ADD  CONSTRAINT [EAssetFeature_AssetCategory] FOREIGN KEY([AssetCategoryID])
REFERENCES [dbo].[AssetCategories] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatures] CHECK CONSTRAINT [EAssetFeature_AssetCategory]
GO
ALTER TABLE [dbo].[AssetFeatures]  WITH CHECK ADD  CONSTRAINT [EAssetFeature_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatures] CHECK CONSTRAINT [EAssetFeature_Currency]
GO
ALTER TABLE [dbo].[AssetFeatures]  WITH CHECK ADD  CONSTRAINT [EAssetFeature_Make] FOREIGN KEY([MakeId])
REFERENCES [dbo].[Makes] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatures] CHECK CONSTRAINT [EAssetFeature_Make]
GO
ALTER TABLE [dbo].[AssetFeatures]  WITH CHECK ADD  CONSTRAINT [EAssetFeature_Manufacturer] FOREIGN KEY([ManufacturerId])
REFERENCES [dbo].[Manufacturers] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatures] CHECK CONSTRAINT [EAssetFeature_Manufacturer]
GO
ALTER TABLE [dbo].[AssetFeatures]  WITH CHECK ADD  CONSTRAINT [EAssetFeature_Model] FOREIGN KEY([ModelId])
REFERENCES [dbo].[Models] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatures] CHECK CONSTRAINT [EAssetFeature_Model]
GO
ALTER TABLE [dbo].[AssetFeatures]  WITH CHECK ADD  CONSTRAINT [EAssetFeature_Product] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Products] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatures] CHECK CONSTRAINT [EAssetFeature_Product]
GO
ALTER TABLE [dbo].[AssetFeatures]  WITH CHECK ADD  CONSTRAINT [EAssetFeature_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatures] CHECK CONSTRAINT [EAssetFeature_State]
GO
ALTER TABLE [dbo].[AssetFeatures]  WITH CHECK ADD  CONSTRAINT [EAssetFeature_Type] FOREIGN KEY([TypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatures] CHECK CONSTRAINT [EAssetFeature_Type]
GO
