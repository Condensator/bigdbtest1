SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetCatalogs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CollateralCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Class2Id] [bigint] NULL,
	[Class3] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsInsuranceRequired] [bit] NOT NULL,
	[FMV_Amount] [decimal](16, 2) NULL,
	[FMV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsCollateralTrackingRequired] [bit] NOT NULL,
	[IsUpgradeEligible] [bit] NOT NULL,
	[Usefullife] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ManufacturerId] [bigint] NOT NULL,
	[ProductId] [bigint] NULL,
	[AssetCategoryId] [bigint] NULL,
	[AssetTypeId] [bigint] NULL,
	[AssetClassADRId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ProductSubTypeId] [bigint] NULL,
	[MakeId] [bigint] NULL,
	[ModelId] [bigint] NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetCatalogs]  WITH CHECK ADD  CONSTRAINT [EAssetCatalog_AssetCategory] FOREIGN KEY([AssetCategoryId])
REFERENCES [dbo].[AssetCategories] ([Id])
GO
ALTER TABLE [dbo].[AssetCatalogs] CHECK CONSTRAINT [EAssetCatalog_AssetCategory]
GO
ALTER TABLE [dbo].[AssetCatalogs]  WITH CHECK ADD  CONSTRAINT [EAssetCatalog_AssetClassADR] FOREIGN KEY([AssetClassADRId])
REFERENCES [dbo].[AssetClassADRConfigs] ([Id])
GO
ALTER TABLE [dbo].[AssetCatalogs] CHECK CONSTRAINT [EAssetCatalog_AssetClassADR]
GO
ALTER TABLE [dbo].[AssetCatalogs]  WITH CHECK ADD  CONSTRAINT [EAssetCatalog_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetCatalogs] CHECK CONSTRAINT [EAssetCatalog_AssetType]
GO
ALTER TABLE [dbo].[AssetCatalogs]  WITH CHECK ADD  CONSTRAINT [EAssetCatalog_Class2] FOREIGN KEY([Class2Id])
REFERENCES [dbo].[AssetClass2] ([Id])
GO
ALTER TABLE [dbo].[AssetCatalogs] CHECK CONSTRAINT [EAssetCatalog_Class2]
GO
ALTER TABLE [dbo].[AssetCatalogs]  WITH CHECK ADD  CONSTRAINT [EAssetCatalog_Make] FOREIGN KEY([MakeId])
REFERENCES [dbo].[Makes] ([Id])
GO
ALTER TABLE [dbo].[AssetCatalogs] CHECK CONSTRAINT [EAssetCatalog_Make]
GO
ALTER TABLE [dbo].[AssetCatalogs]  WITH CHECK ADD  CONSTRAINT [EAssetCatalog_Manufacturer] FOREIGN KEY([ManufacturerId])
REFERENCES [dbo].[Manufacturers] ([Id])
GO
ALTER TABLE [dbo].[AssetCatalogs] CHECK CONSTRAINT [EAssetCatalog_Manufacturer]
GO
ALTER TABLE [dbo].[AssetCatalogs]  WITH CHECK ADD  CONSTRAINT [EAssetCatalog_Model] FOREIGN KEY([ModelId])
REFERENCES [dbo].[Models] ([Id])
GO
ALTER TABLE [dbo].[AssetCatalogs] CHECK CONSTRAINT [EAssetCatalog_Model]
GO
ALTER TABLE [dbo].[AssetCatalogs]  WITH CHECK ADD  CONSTRAINT [EAssetCatalog_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[AssetCatalogs] CHECK CONSTRAINT [EAssetCatalog_Portfolio]
GO
ALTER TABLE [dbo].[AssetCatalogs]  WITH CHECK ADD  CONSTRAINT [EAssetCatalog_Product] FOREIGN KEY([ProductId])
REFERENCES [dbo].[Products] ([Id])
GO
ALTER TABLE [dbo].[AssetCatalogs] CHECK CONSTRAINT [EAssetCatalog_Product]
GO
ALTER TABLE [dbo].[AssetCatalogs]  WITH CHECK ADD  CONSTRAINT [EAssetCatalog_ProductSubType] FOREIGN KEY([ProductSubTypeId])
REFERENCES [dbo].[ProductSubTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetCatalogs] CHECK CONSTRAINT [EAssetCatalog_ProductSubType]
GO
