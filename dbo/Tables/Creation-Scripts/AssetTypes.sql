SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsSoft] [bit] NOT NULL,
	[IsQualifiedTechnicalEquipment] [bit] NOT NULL,
	[EconomicLifeInMonths] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[ExcludeFrom90PercentTest] [bit] NOT NULL,
	[IsHighRisk] [bit] NOT NULL,
	[IsInsuranceRequired] [bit] NOT NULL,
	[EquipmentClass] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IRSClassCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsCollateralTracking] [bit] NOT NULL,
	[IsEligibleForFPI] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ProductId] [bigint] NULL,
	[CostTypeId] [bigint] NOT NULL,
	[AssetClassCodeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsElectronicallyDelivered] [bit] NOT NULL,
	[TaxExemptRuleId] [bigint] NOT NULL,
	[BookDepreciationTemplateId] [bigint] NULL,
	[Serialized] [bit] NOT NULL,
	[ReviewFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[ExemptProperty] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[CapitalCostAllowanceClassId] [bigint] NULL,
	[PortfolioId] [bigint] NOT NULL,
	[PricingGroupId] [bigint] NULL,
	[IsTrailer] [bit] NOT NULL,
	[IsRoadTaxApplicable] [bit] NOT NULL,
	[IsPermissibleMassRange] [bit] NOT NULL,
	[RoadTaxType] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[FlatFeeParameter] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[AssetCategoryId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetTypes]  WITH CHECK ADD  CONSTRAINT [EAssetType_AssetCategory] FOREIGN KEY([AssetCategoryId])
REFERENCES [dbo].[AssetCategories] ([Id])
GO
ALTER TABLE [dbo].[AssetTypes] CHECK CONSTRAINT [EAssetType_AssetCategory]
GO
ALTER TABLE [dbo].[AssetTypes]  WITH CHECK ADD  CONSTRAINT [EAssetType_AssetClassCode] FOREIGN KEY([AssetClassCodeId])
REFERENCES [dbo].[AssetClassCodes] ([Id])
GO
ALTER TABLE [dbo].[AssetTypes] CHECK CONSTRAINT [EAssetType_AssetClassCode]
GO
ALTER TABLE [dbo].[AssetTypes]  WITH CHECK ADD  CONSTRAINT [EAssetType_BookDepreciationTemplate] FOREIGN KEY([BookDepreciationTemplateId])
REFERENCES [dbo].[BookDepreciationTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetTypes] CHECK CONSTRAINT [EAssetType_BookDepreciationTemplate]
GO
ALTER TABLE [dbo].[AssetTypes]  WITH CHECK ADD  CONSTRAINT [EAssetType_CapitalCostAllowanceClass] FOREIGN KEY([CapitalCostAllowanceClassId])
REFERENCES [dbo].[CapitalCostAllowanceClasses] ([Id])
GO
ALTER TABLE [dbo].[AssetTypes] CHECK CONSTRAINT [EAssetType_CapitalCostAllowanceClass]
GO
ALTER TABLE [dbo].[AssetTypes]  WITH CHECK ADD  CONSTRAINT [EAssetType_CostType] FOREIGN KEY([CostTypeId])
REFERENCES [dbo].[CostTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetTypes] CHECK CONSTRAINT [EAssetType_CostType]
GO
ALTER TABLE [dbo].[AssetTypes]  WITH CHECK ADD  CONSTRAINT [EAssetType_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[AssetTypes] CHECK CONSTRAINT [EAssetType_Portfolio]
GO
ALTER TABLE [dbo].[AssetTypes]  WITH CHECK ADD  CONSTRAINT [EAssetType_PricingGroup] FOREIGN KEY([PricingGroupId])
REFERENCES [dbo].[PricingGroups] ([Id])
GO
ALTER TABLE [dbo].[AssetTypes] CHECK CONSTRAINT [EAssetType_PricingGroup]
GO
ALTER TABLE [dbo].[AssetTypes]  WITH CHECK ADD  CONSTRAINT [EAssetType_Product] FOREIGN KEY([ProductId])
REFERENCES [dbo].[Products] ([Id])
GO
ALTER TABLE [dbo].[AssetTypes] CHECK CONSTRAINT [EAssetType_Product]
GO
ALTER TABLE [dbo].[AssetTypes]  WITH CHECK ADD  CONSTRAINT [EAssetType_TaxExemptRule] FOREIGN KEY([TaxExemptRuleId])
REFERENCES [dbo].[TaxExemptRules] ([Id])
GO
ALTER TABLE [dbo].[AssetTypes] CHECK CONSTRAINT [EAssetType_TaxExemptRule]
GO
