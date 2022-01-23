SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetFeatureSetDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[Quantity] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ManufacturerId] [bigint] NULL,
	[TypeId] [bigint] NOT NULL,
	[AssetFeatureSetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[StateId] [bigint] NULL,
	[AssetCategoryId] [bigint] NULL,
	[ProductId] [bigint] NULL,
	[MakeId] [bigint] NULL,
	[ModelId] [bigint] NULL,
	[AssetCatalogId] [bigint] NULL,
	[Value_Amount] [decimal](16, 2) NOT NULL,
	[Value_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetFeatureSetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetFeatureSet_AssetFeatureSetDetails] FOREIGN KEY([AssetFeatureSetId])
REFERENCES [dbo].[AssetFeatureSets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails] CHECK CONSTRAINT [EAssetFeatureSet_AssetFeatureSetDetails]
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetFeatureSetDetail_AssetCatalog] FOREIGN KEY([AssetCatalogId])
REFERENCES [dbo].[AssetCatalogs] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails] CHECK CONSTRAINT [EAssetFeatureSetDetail_AssetCatalog]
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetFeatureSetDetail_AssetCategory] FOREIGN KEY([AssetCategoryId])
REFERENCES [dbo].[AssetCategories] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails] CHECK CONSTRAINT [EAssetFeatureSetDetail_AssetCategory]
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetFeatureSetDetail_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails] CHECK CONSTRAINT [EAssetFeatureSetDetail_Currency]
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetFeatureSetDetail_Make] FOREIGN KEY([MakeId])
REFERENCES [dbo].[Makes] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails] CHECK CONSTRAINT [EAssetFeatureSetDetail_Make]
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetFeatureSetDetail_Manufacturer] FOREIGN KEY([ManufacturerId])
REFERENCES [dbo].[Manufacturers] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails] CHECK CONSTRAINT [EAssetFeatureSetDetail_Manufacturer]
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetFeatureSetDetail_Model] FOREIGN KEY([ModelId])
REFERENCES [dbo].[Models] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails] CHECK CONSTRAINT [EAssetFeatureSetDetail_Model]
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetFeatureSetDetail_Product] FOREIGN KEY([ProductId])
REFERENCES [dbo].[Products] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails] CHECK CONSTRAINT [EAssetFeatureSetDetail_Product]
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetFeatureSetDetail_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails] CHECK CONSTRAINT [EAssetFeatureSetDetail_State]
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetFeatureSetDetail_Type] FOREIGN KEY([TypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetFeatureSetDetails] CHECK CONSTRAINT [EAssetFeatureSetDetail_Type]
GO
