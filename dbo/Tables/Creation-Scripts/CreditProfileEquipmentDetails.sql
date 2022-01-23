SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditProfileEquipmentDetails](
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
	[CreditApprovedStructureId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsFromQuote] [bit] NOT NULL,
	[ProgramAssetTypeId] [bigint] NULL,
	[EquipmentVendorId] [bigint] NULL,
	[VATAmount_Amount] [decimal](16, 2) NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxCodeId] [bigint] NULL,
	[Cost_Amount] [decimal](16, 2) NOT NULL,
	[Cost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RentFactor] [decimal](18, 8) NOT NULL,
	[Rent_Amount] [decimal](16, 2) NOT NULL,
	[Rent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestRate] [decimal](10, 6) NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CustomerExpectedResidualFactor] [decimal](18, 8) NOT NULL,
	[CustomerExpectedResidual_Amount] [decimal](16, 2) NOT NULL,
	[CustomerExpectedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[GuaranteedResidualFactor] [decimal](18, 8) NOT NULL,
	[GuaranteedResidual_Amount] [decimal](16, 2) NOT NULL,
	[GuaranteedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PricingGroupId] [bigint] NOT NULL,
	[InterimRentFactor] [decimal](18, 8) NOT NULL,
	[InterimRent_Amount] [decimal](16, 2) NOT NULL,
	[InterimRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApprovedStructure_CreditProfileEquipmentDetails] FOREIGN KEY([CreditApprovedStructureId])
REFERENCES [dbo].[CreditApprovedStructures] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails] CHECK CONSTRAINT [ECreditApprovedStructure_CreditProfileEquipmentDetails]
GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditProfileEquipmentDetail_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails] CHECK CONSTRAINT [ECreditProfileEquipmentDetail_AssetType]
GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditProfileEquipmentDetail_EquipmentVendor] FOREIGN KEY([EquipmentVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails] CHECK CONSTRAINT [ECreditProfileEquipmentDetail_EquipmentVendor]
GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditProfileEquipmentDetail_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails] CHECK CONSTRAINT [ECreditProfileEquipmentDetail_Location]
GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditProfileEquipmentDetail_PricingGroup] FOREIGN KEY([PricingGroupId])
REFERENCES [dbo].[PricingGroups] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails] CHECK CONSTRAINT [ECreditProfileEquipmentDetail_PricingGroup]
GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditProfileEquipmentDetail_ProgramAssetType] FOREIGN KEY([ProgramAssetTypeId])
REFERENCES [dbo].[ProgramAssetTypes] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails] CHECK CONSTRAINT [ECreditProfileEquipmentDetail_ProgramAssetType]
GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [ECreditProfileEquipmentDetail_TaxCode] FOREIGN KEY([TaxCodeId])
REFERENCES [dbo].[TaxCodes] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileEquipmentDetails] CHECK CONSTRAINT [ECreditProfileEquipmentDetail_TaxCode]
GO
