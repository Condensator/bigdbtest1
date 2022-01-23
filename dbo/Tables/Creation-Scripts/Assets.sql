SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Assets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[AcquisitionDate] [date] NOT NULL,
	[PartNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[UsageCondition] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[Quantity] [int] NOT NULL,
	[InServiceDate] [date] NOT NULL,
	[IsEligibleForPropertyTax] [bit] NOT NULL,
	[Status] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[FinancialType] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[MoveChildAssets] [bit] NOT NULL,
	[AssetMode] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[PropertyTaxCost_Amount] [decimal](16, 2) NOT NULL,
	[PropertyTaxCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PropertyTaxDate] [date] NULL,
	[ProspectiveContract] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CurrencyCode] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsTaxExempt] [bit] NOT NULL,
	[ModelYear] [decimal](4, 0) NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[OwnershipStatus] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[PropertyTaxResponsibility] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[PurchaseOrderDate] [date] NULL,
	[GrossVehicleWeight] [int] NULL,
	[WeightMeasure] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsOffLease] [bit] NOT NULL,
	[IsElectronicallyDelivered] [bit] NOT NULL,
	[IsSaleLeaseback] [bit] NOT NULL,
	[IsParent] [bit] NOT NULL,
	[IsOnCommencedLease] [bit] NOT NULL,
	[IsTakedownAsset] [bit] NOT NULL,
	[IsSystemCreated] [bit] NOT NULL,
	[PreviousSequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SubStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ManufacturerId] [bigint] NULL,
	[TypeId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CustomerId] [bigint] NULL,
	[ParentAssetId] [bigint] NULL,
	[FeatureSetId] [bigint] NULL,
	[ClearAccumulatedGLTemplateId] [bigint] NULL,
	[TitleTransferCodeId] [bigint] NULL,
	[AssetUsageId] [bigint] NULL,
	[PropertyTaxReportCodeId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[VendorAssetCategoryId] [bigint] NULL,
	[SaleLeasebackCodeId] [bigint] NULL,
	[RemarketingVendorId] [bigint] NULL,
	[PlaceholderAssetId] [bigint] NULL,
	[SalesTaxExemptionLevelId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DealerCost_Amount] [decimal](16, 2) NULL,
	[DealerCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DMDPercentage] [decimal](5, 2) NULL,
	[CustomerAssetNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[VendorOrderNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetCatalogId] [bigint] NULL,
	[ProductId] [bigint] NULL,
	[AssetClass2Id] [bigint] NULL,
	[IsManufacturerOverride] [bit] NOT NULL,
	[AssetCategoryId] [bigint] NULL,
	[Class1] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[Class3] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Description2] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ManufacturerOverride] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TaxExemptRuleId] [bigint] NOT NULL,
	[IsReversed] [bit] NOT NULL,
	[MakeId] [bigint] NULL,
	[ModelId] [bigint] NULL,
	[MaintenanceVendorId] [bigint] NULL,
	[IsSerializedAsset] [bit] NOT NULL,
	[Residual_Amount] [decimal](16, 2) NOT NULL,
	[Residual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsVehicle] [bit] NOT NULL,
	[InventoryRemarketerId] [bigint] NULL,
	[SpecifiedLeasingProperty] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[ExemptProperty] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[IsLeaseComponent] [bit] NOT NULL,
	[IsServiceOnly] [bit] NOT NULL,
	[IsSKU] [bit] NOT NULL,
	[IsTaxParameterChangedForLeasedAsset] [bit] NOT NULL,
	[DisposedDate] [date] NULL,
	[Salvage_Amount] [decimal](16, 2) NOT NULL,
	[Salvage_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PricingGroupId] [bigint] NULL,
	[IsServiced] [bit] NULL,
	[IsFixedAsset] [bit] NULL,
	[ValueExclVAT_Amount] [decimal](16, 2) NOT NULL,
	[ValueExclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ValueInclVAT_Amount] [decimal](16, 2) NULL,
	[ValueInclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsVat] [bit] NULL,
	[IsImport] [bit] NULL,
	[IsPreLeased] [bit] NULL,
	[DateofProduction] [date] NOT NULL,
	[AgeofAsset] [decimal](16, 2) NULL,
	[Modification] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[TrimLevel] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[AcquiredDate] [date] NULL,
	[DeliveredDate] [date] NULL,
	[SalePurchaseAgreementNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[SalePurchaseAgreementDate] [date] NULL,
	[CreationStatus] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[RoadTaxType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[VendorId] [bigint] NOT NULL,
	[IsFromCreditApp] [bit] NOT NULL,
	[CreditApplicationEquipmentDetailId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_AssetCatalog] FOREIGN KEY([AssetCatalogId])
REFERENCES [dbo].[AssetCatalogs] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_AssetCatalog]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_AssetCategory] FOREIGN KEY([AssetCategoryId])
REFERENCES [dbo].[AssetCategories] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_AssetCategory]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_AssetClass2] FOREIGN KEY([AssetClass2Id])
REFERENCES [dbo].[AssetClass2] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_AssetClass2]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_AssetUsage] FOREIGN KEY([AssetUsageId])
REFERENCES [dbo].[AssetUsages] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_AssetUsage]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_ClearAccumulatedGLTemplate] FOREIGN KEY([ClearAccumulatedGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_ClearAccumulatedGLTemplate]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_CreditApplicationEquipmentDetail] FOREIGN KEY([CreditApplicationEquipmentDetailId])
REFERENCES [dbo].[CreditApplicationEquipmentDetails] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_CreditApplicationEquipmentDetail]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_Customer]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_FeatureSet] FOREIGN KEY([FeatureSetId])
REFERENCES [dbo].[AssetFeatureSets] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_FeatureSet]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_InventoryRemarketer] FOREIGN KEY([InventoryRemarketerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_InventoryRemarketer]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_LegalEntity]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_MaintenanceVendor] FOREIGN KEY([MaintenanceVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_MaintenanceVendor]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_Make] FOREIGN KEY([MakeId])
REFERENCES [dbo].[Makes] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_Make]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_Manufacturer] FOREIGN KEY([ManufacturerId])
REFERENCES [dbo].[Manufacturers] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_Manufacturer]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_Model] FOREIGN KEY([ModelId])
REFERENCES [dbo].[Models] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_Model]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_ParentAsset] FOREIGN KEY([ParentAssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_ParentAsset]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_PlaceholderAsset] FOREIGN KEY([PlaceholderAssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_PlaceholderAsset]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_PricingGroup] FOREIGN KEY([PricingGroupId])
REFERENCES [dbo].[PricingGroups] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_PricingGroup]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_Product] FOREIGN KEY([ProductId])
REFERENCES [dbo].[Products] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_Product]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_PropertyTaxReportCode] FOREIGN KEY([PropertyTaxReportCodeId])
REFERENCES [dbo].[PropertyTaxReportCodeConfigs] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_PropertyTaxReportCode]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_RemarketingVendor] FOREIGN KEY([RemarketingVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_RemarketingVendor]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_SaleLeasebackCode] FOREIGN KEY([SaleLeasebackCodeId])
REFERENCES [dbo].[SaleLeasebackCodeConfigs] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_SaleLeasebackCode]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_SalesTaxExemptionLevel] FOREIGN KEY([SalesTaxExemptionLevelId])
REFERENCES [dbo].[SalesTaxExemptionLevelConfigs] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_SalesTaxExemptionLevel]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_State]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_TaxExemptRule] FOREIGN KEY([TaxExemptRuleId])
REFERENCES [dbo].[TaxExemptRules] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_TaxExemptRule]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_TitleTransferCode] FOREIGN KEY([TitleTransferCodeId])
REFERENCES [dbo].[TitleTransferCodes] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_TitleTransferCode]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_Type] FOREIGN KEY([TypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_Type]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_Vendor]
GO
ALTER TABLE [dbo].[Assets]  WITH CHECK ADD  CONSTRAINT [EAsset_VendorAssetCategory] FOREIGN KEY([VendorAssetCategoryId])
REFERENCES [dbo].[VendorAssetCategoryConfigs] ([Id])
GO
ALTER TABLE [dbo].[Assets] CHECK CONSTRAINT [EAsset_VendorAssetCategory]
GO
