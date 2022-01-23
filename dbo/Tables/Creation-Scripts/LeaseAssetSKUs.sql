SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseAssetSKUs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[NBV_Amount] [decimal](16, 2) NOT NULL,
	[NBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerCost_Amount] [decimal](16, 2) NOT NULL,
	[CustomerCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FMV_Amount] [decimal](16, 2) NOT NULL,
	[FMV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SpecificCostAdjustment_Amount] [decimal](16, 2) NOT NULL,
	[SpecificCostAdjustment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SpecificCostAdjustmentOnCommencement_Amount] [decimal](16, 2) NOT NULL,
	[SpecificCostAdjustmentOnCommencement_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterimRent_Amount] [decimal](16, 2) NOT NULL,
	[InterimRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Rent_Amount] [decimal](16, 2) NOT NULL,
	[Rent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPRent_Amount] [decimal](16, 2) NOT NULL,
	[OTPRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RVRecapAmount_Amount] [decimal](16, 2) NOT NULL,
	[RVRecapAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SupplementalRent_Amount] [decimal](16, 2) NOT NULL,
	[SupplementalRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BookedResidual_Amount] [decimal](16, 2) NOT NULL,
	[BookedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerGuaranteedResidual_Amount] [decimal](16, 2) NOT NULL,
	[CustomerGuaranteedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ThirdPartyGuaranteedResidual_Amount] [decimal](16, 2) NOT NULL,
	[ThirdPartyGuaranteedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ResidualValueInsurance_Amount] [decimal](16, 2) NOT NULL,
	[ResidualValueInsurance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[MaturityPayment_Amount] [decimal](16, 2) NOT NULL,
	[MaturityPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrepaidUpfrontTax_Amount] [decimal](16, 2) NOT NULL,
	[PrepaidUpfrontTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsLeaseComponent] [bit] NOT NULL,
	[AssetSKUId] [bigint] NULL,
	[LeaseAssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustomerExpectedResidual_Amount] [decimal](16, 2) NOT NULL,
	[CustomerExpectedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Markup_Amount] [decimal](16, 2) NOT NULL,
	[Markup_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterimMarkup_Amount] [decimal](16, 2) NOT NULL,
	[InterimMarkup_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ETCAdjustmentAmount_Amount] [decimal](16, 2) NOT NULL,
	[ETCAdjustmentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CapitalizedInterimInterest_Amount] [decimal](16, 2) NOT NULL,
	[CapitalizedInterimInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CapitalizedInterimRent_Amount] [decimal](16, 2) NOT NULL,
	[CapitalizedInterimRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CapitalizedSalesTax_Amount] [decimal](16, 2) NOT NULL,
	[CapitalizedSalesTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CapitalizedIDC_Amount] [decimal](16, 2) NOT NULL,
	[CapitalizedIDC_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CapitalizedProgressPayment_Amount] [decimal](16, 2) NOT NULL,
	[CapitalizedProgressPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CapitalizedAdditionalCharge_Amount] [decimal](16, 2) NOT NULL,
	[CapitalizedAdditionalCharge_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccumulatedDepreciation_Amount] [decimal](16, 2) NOT NULL,
	[AccumulatedDepreciation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterimRentFactor] [decimal](18, 8) NOT NULL,
	[RentFactor] [decimal](18, 8) NOT NULL,
	[OTPRentFactor] [decimal](18, 8) NOT NULL,
	[RVRecapFactor] [decimal](18, 8) NOT NULL,
	[SupplementalRentFactor] [decimal](18, 8) NOT NULL,
	[BookedResidualFactor] [decimal](18, 8) NOT NULL,
	[CustomerExpectedResidualFactor] [decimal](18, 8) NOT NULL,
	[CustomerGuaranteedResidualFactor] [decimal](18, 8) NOT NULL,
	[ThirdPartyGuaranteedResidualFactor] [decimal](18, 8) NOT NULL,
	[ResidualValueInsuranceFactor] [decimal](18, 8) NOT NULL,
	[MaturityPaymentFactor] [decimal](18, 8) NOT NULL,
	[OriginalCapitalizedAmount_Amount] [decimal](16, 2) NOT NULL,
	[OriginalCapitalizedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SalesTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[SalesTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreditProfileEquipmentDetailId] [bigint] NULL,
	[PreCapitalizationRent_Amount] [decimal](16, 2) NOT NULL,
	[PreCapitalizationRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseAssetSKUs]  WITH NOCHECK ADD  CONSTRAINT [ELeaseAsset_LeaseAssetSKUs] FOREIGN KEY([LeaseAssetId])
REFERENCES [dbo].[LeaseAssets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseAssetSKUs] NOCHECK CONSTRAINT [ELeaseAsset_LeaseAssetSKUs]
GO
ALTER TABLE [dbo].[LeaseAssetSKUs]  WITH NOCHECK ADD  CONSTRAINT [ELeaseAssetSKU_AssetSKU] FOREIGN KEY([AssetSKUId])
REFERENCES [dbo].[AssetSKUs] ([Id])
GO
ALTER TABLE [dbo].[LeaseAssetSKUs] NOCHECK CONSTRAINT [ELeaseAssetSKU_AssetSKU]
GO
ALTER TABLE [dbo].[LeaseAssetSKUs]  WITH CHECK ADD  CONSTRAINT [ELeaseAssetSKU_CreditProfileEquipmentDetail] FOREIGN KEY([CreditProfileEquipmentDetailId])
REFERENCES [dbo].[CreditProfileEquipmentDetails] ([Id])
GO
ALTER TABLE [dbo].[LeaseAssetSKUs] CHECK CONSTRAINT [ELeaseAssetSKU_CreditProfileEquipmentDetail]
GO
