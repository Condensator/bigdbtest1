SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetEnMasseUpdateDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Alias] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[AcquisitionDate] [date] NULL,
	[PartNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[UsageCondition] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Quantity] [int] NOT NULL,
	[InServiceDate] [date] NOT NULL,
	[IsEligibleForPropertyTax] [bit] NOT NULL,
	[PropertyTaxCost_Amount] [decimal](16, 2) NOT NULL,
	[PropertyTaxCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PropertyTaxDate] [date] NULL,
	[ProspectiveContract] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[OwnershipStatus] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[PurchaseOrderDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[ManufacturerId] [bigint] NULL,
	[TypeId] [bigint] NOT NULL,
	[CustomerId] [bigint] NULL,
	[PropertyTaxReportCodeId] [bigint] NULL,
	[VendorAssetCategoryId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[SaleLeasebackCodeId] [bigint] NULL,
	[AssetEnMasseUpdateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ModelYear] [decimal](4, 0) NULL,
	[VendorOrderNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetCatalogId] [bigint] NULL,
	[IsSaleLeaseback] [bit] NOT NULL,
	[AssetBookValueAdjustmentGLTemplateId] [bigint] NULL,
	[BookDepreciationGLTemplateId] [bigint] NULL,
	[IsElectronicallyDelivered] [bit] NOT NULL,
	[InventoryRemarketerId] [bigint] NULL,
	[MakeId] [bigint] NULL,
	[ModelId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdate_AssetEnMasseUpdateDetails] FOREIGN KEY([AssetEnMasseUpdateId])
REFERENCES [dbo].[AssetEnMasseUpdates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdate_AssetEnMasseUpdateDetails]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_Asset]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_AssetBookValueAdjustmentGLTemplate] FOREIGN KEY([AssetBookValueAdjustmentGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_AssetBookValueAdjustmentGLTemplate]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_AssetCatalog] FOREIGN KEY([AssetCatalogId])
REFERENCES [dbo].[AssetCatalogs] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_AssetCatalog]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_BookDepreciationGLTemplate] FOREIGN KEY([BookDepreciationGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_BookDepreciationGLTemplate]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_Customer]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_InventoryRemarketer] FOREIGN KEY([InventoryRemarketerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_InventoryRemarketer]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_Make] FOREIGN KEY([MakeId])
REFERENCES [dbo].[Makes] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_Make]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_Manufacturer] FOREIGN KEY([ManufacturerId])
REFERENCES [dbo].[Manufacturers] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_Manufacturer]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_Model] FOREIGN KEY([ModelId])
REFERENCES [dbo].[Models] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_Model]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_PropertyTaxReportCode] FOREIGN KEY([PropertyTaxReportCodeId])
REFERENCES [dbo].[PropertyTaxReportCodeConfigs] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_PropertyTaxReportCode]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_SaleLeasebackCode] FOREIGN KEY([SaleLeasebackCodeId])
REFERENCES [dbo].[SaleLeasebackCodeConfigs] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_SaleLeasebackCode]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_State]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_Type] FOREIGN KEY([TypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_Type]
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetEnMasseUpdateDetail_VendorAssetCategory] FOREIGN KEY([VendorAssetCategoryId])
REFERENCES [dbo].[VendorAssetCategoryConfigs] ([Id])
GO
ALTER TABLE [dbo].[AssetEnMasseUpdateDetails] CHECK CONSTRAINT [EAssetEnMasseUpdateDetail_VendorAssetCategory]
GO
