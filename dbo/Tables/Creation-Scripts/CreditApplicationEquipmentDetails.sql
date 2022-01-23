SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditApplicationEquipmentDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [int] NOT NULL,
	[Quantity] [bigint] NOT NULL,
	[TotalCost_Amount] [decimal](16, 2) NOT NULL,
	[TotalCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UsageCondition] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[ModelYear] [decimal](4, 0) NULL,
	[IsNewLocation] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetTypeId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[CreditApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsFromQuote] [bit] NOT NULL,
	[ProgramAssetTypeId] [bigint] NULL,
	[EquipmentVendorId] [bigint] NULL,
	[VATAmount_Amount] [decimal](16, 2) NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxCodeId] [bigint] NULL,
	[EquipmentDescription] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[MakeId] [bigint] NOT NULL,
	[ModelId] [bigint] NOT NULL,
	[Cost_Amount] [decimal](16, 2) NOT NULL,
	[Cost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PricingGroupId] [bigint] NOT NULL,
	[DateOfProduction] [date] NOT NULL,
	[AgeofAsset] [decimal](16, 2) NOT NULL,
	[KW] [decimal](16, 2) NULL,
	[EngineCapacity] [decimal](16, 2) NULL,
	[IsVAT] [bit] NOT NULL,
	[ValueInclVAT_Amount] [decimal](16, 2) NOT NULL,
	[ValueInclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetClassConfigId] [bigint] NULL,
	[IsImported] [bit] NULL,
	[TechnicallyPermissibleMass] [decimal](16, 2) NULL,
	[LoadCapacity] [decimal](16, 2) NULL,
	[Seats] [int] NULL,
	[InsuranceAssessment_Amount] [decimal](16, 2) NOT NULL,
	[InsuranceAssessment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_CreditApplicationEquipmentDetails] FOREIGN KEY([CreditApplicationId])
REFERENCES [dbo].[CreditApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails] CHECK CONSTRAINT [ECreditApplication_CreditApplicationEquipmentDetails]
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationEquipmentDetail_AssetClassConfig] FOREIGN KEY([AssetClassConfigId])
REFERENCES [dbo].[AssetClassConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails] CHECK CONSTRAINT [ECreditApplicationEquipmentDetail_AssetClassConfig]
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationEquipmentDetail_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails] CHECK CONSTRAINT [ECreditApplicationEquipmentDetail_AssetType]
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationEquipmentDetail_EquipmentVendor] FOREIGN KEY([EquipmentVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails] CHECK CONSTRAINT [ECreditApplicationEquipmentDetail_EquipmentVendor]
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationEquipmentDetail_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails] CHECK CONSTRAINT [ECreditApplicationEquipmentDetail_Location]
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationEquipmentDetail_Make] FOREIGN KEY([MakeId])
REFERENCES [dbo].[Makes] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails] CHECK CONSTRAINT [ECreditApplicationEquipmentDetail_Make]
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationEquipmentDetail_Model] FOREIGN KEY([ModelId])
REFERENCES [dbo].[Models] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails] CHECK CONSTRAINT [ECreditApplicationEquipmentDetail_Model]
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationEquipmentDetail_PricingGroup] FOREIGN KEY([PricingGroupId])
REFERENCES [dbo].[PricingGroups] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails] CHECK CONSTRAINT [ECreditApplicationEquipmentDetail_PricingGroup]
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationEquipmentDetail_ProgramAssetType] FOREIGN KEY([ProgramAssetTypeId])
REFERENCES [dbo].[ProgramAssetTypes] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails] CHECK CONSTRAINT [ECreditApplicationEquipmentDetail_ProgramAssetType]
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationEquipmentDetail_TaxCode] FOREIGN KEY([TaxCodeId])
REFERENCES [dbo].[TaxCodes] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationEquipmentDetails] CHECK CONSTRAINT [ECreditApplicationEquipmentDetail_TaxCode]
GO
