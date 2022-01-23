SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayoffAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetValuation_Amount] [decimal](16, 2) NOT NULL,
	[AssetValuation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OLV_Amount] [decimal](16, 2) NOT NULL,
	[OLV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[SubStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[PlaceholderNBV_Amount] [decimal](16, 2) NOT NULL,
	[PlaceholderNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PlaceholderRent_Amount] [decimal](16, 2) NOT NULL,
	[PlaceholderRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReturnTo] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[DepreciationTerm] [int] NOT NULL,
	[PayoffAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayoffAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BuyoutAmount_Amount] [decimal](16, 2) NOT NULL,
	[BuyoutAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UtilitySaleAtAuction] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PlaceholderAssetId] [bigint] NULL,
	[NegativeReturnAssetId] [bigint] NULL,
	[SyndicatedNBV_Amount] [decimal](16, 2) NOT NULL,
	[SyndicatedNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RemainingRentals_Amount] [decimal](16, 2) NOT NULL,
	[RemainingRentals_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SyndicatedRemainingRentals_Amount] [decimal](16, 2) NOT NULL,
	[SyndicatedRemainingRentals_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FloatRateRemainingRentals_Amount] [decimal](16, 2) NOT NULL,
	[FloatRateRemainingRentals_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SyndicatedFloatRateRemainingRentals_Amount] [decimal](16, 2) NOT NULL,
	[SyndicatedFloatRateRemainingRentals_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NBVAsOfEffectiveDate_Amount] [decimal](16, 2) NOT NULL,
	[NBVAsOfEffectiveDate_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NBV_Amount] [decimal](16, 2) NOT NULL,
	[NBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerCost_Amount] [decimal](16, 2) NOT NULL,
	[CustomerCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FinancialType] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[OutstandingRentalBilled_Amount] [decimal](16, 2) NOT NULL,
	[OutstandingRentalBilled_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OutstandingRentalsUnbilled_Amount] [decimal](16, 2) NOT NULL,
	[OutstandingRentalsUnbilled_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UnearnedIncome_Amount] [decimal](16, 2) NOT NULL,
	[UnearnedIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UnearnedResidualIncome_Amount] [decimal](16, 2) NOT NULL,
	[UnearnedResidualIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccumulatedNBVImpairment_Amount] [decimal](16, 2) NOT NULL,
	[AccumulatedNBVImpairment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FixedTermDepreciation_Amount] [decimal](16, 2) NOT NULL,
	[FixedTermDepreciation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DeferredRentalIncome_Amount] [decimal](16, 2) NOT NULL,
	[DeferredRentalIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CalculatedNBV_Amount] [decimal](16, 2) NOT NULL,
	[CalculatedNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPAccumulatedNBVImpairment_Amount] [decimal](16, 2) NOT NULL,
	[OTPAccumulatedNBVImpairment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPDepreciation_Amount] [decimal](16, 2) NOT NULL,
	[OTPDepreciation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPDeferredRentalIncome_Amount] [decimal](16, 2) NOT NULL,
	[OTPDeferredRentalIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LocationCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[WriteDownAmount_Amount] [decimal](16, 2) NOT NULL,
	[WriteDownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LessorOwnedNBV_Amount] [decimal](16, 2) NOT NULL,
	[LessorOwnedNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RepossessionType] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[IsAssetDroppedOff] [bit] NOT NULL,
	[DropOffDate] [date] NULL,
	[IsSplit] [bit] NOT NULL,
	[IsPartiallyOwned] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeaseAssetId] [bigint] NOT NULL,
	[RemarketingVendorId] [bigint] NULL,
	[AssetLocationId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[RepossessionAgentId] [bigint] NULL,
	[DropOffLocationId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[PayoffId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DeferredTaxCleared_Amount] [decimal](16, 2) NOT NULL,
	[DeferredTaxCleared_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[HeldForSale] [bit] NOT NULL,
	[InventoryBookDepGLTemplateId] [bigint] NULL,
	[AssetBookValueAdjustmentGLTemplateId] [bigint] NULL,
	[BookDepreciationTemplateId] [bigint] NULL,
	[ProspectiveContract] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TerminationReasonConfigId] [bigint] NULL,
	[LessorOwnedBookedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LessorOwnedBookedResidual_Amount] [decimal](16, 2) NOT NULL,
	[FMV_Amount] [decimal](16, 2) NOT NULL,
	[FMV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DeferredSellingProfitIncomeBalance_Amount] [decimal](16, 2) NOT NULL,
	[DeferredSellingProfitIncomeBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseComponentLessorOwnedNBV_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponentLessorOwnedNBV_Amount] [decimal](16, 2) NOT NULL,
	[LeaseComponentNBVAsOfEffectiveDate_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponentNBVAsOfEffectiveDate_Amount] [decimal](16, 2) NOT NULL,
	[LeaseComponentLessorOwnedNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonLeaseComponentLessorOwnedNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseComponentNBVAsOfEffectiveDate_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonLeaseComponentNBVAsOfEffectiveDate_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseComponentUnearnedIncome_Amount] [decimal](16, 2) NOT NULL,
	[LeaseComponentUnearnedIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonLeaseComponentUnearnedIncome_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponentUnearnedIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseComponentUnearnedResidualIncome_Amount] [decimal](16, 2) NOT NULL,
	[LeaseComponentUnearnedResidualIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonLeaseComponentUnearnedResidualIncome_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponentUnearnedResidualIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseComponentAssetValuation_Amount] [decimal](16, 2) NOT NULL,
	[LeaseComponentAssetValuation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonLeaseComponentAssetValuation_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponentAssetValuation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseComponentOLV_Amount] [decimal](16, 2) NOT NULL,
	[LeaseComponentOLV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonLeaseComponentOLV_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponentOLV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UpfrontTaxAssessedAssetLocationId] [bigint] NULL,
	[UpfrontTaxAssessedCustomerLocationId] [bigint] NULL,
	[PayoffVATAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayoffVATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BuyoutVATAmount_Amount] [decimal](16, 2) NOT NULL,
	[BuyoutVATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoff_PayoffAssets] FOREIGN KEY([PayoffId])
REFERENCES [dbo].[Payoffs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoff_PayoffAssets]
GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_AssetBookValueAdjustmentGLTemplate] FOREIGN KEY([AssetBookValueAdjustmentGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoffAsset_AssetBookValueAdjustmentGLTemplate]
GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_AssetLocation] FOREIGN KEY([AssetLocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoffAsset_AssetLocation]
GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoffAsset_BillTo]
GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_BookDepreciationTemplate] FOREIGN KEY([BookDepreciationTemplateId])
REFERENCES [dbo].[BookDepreciationTemplates] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoffAsset_BookDepreciationTemplate]
GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoffAsset_Customer]
GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_DropOffLocation] FOREIGN KEY([DropOffLocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoffAsset_DropOffLocation]
GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_InventoryBookDepGLTemplate] FOREIGN KEY([InventoryBookDepGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoffAsset_InventoryBookDepGLTemplate]
GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_LeaseAsset] FOREIGN KEY([LeaseAssetId])
REFERENCES [dbo].[LeaseAssets] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoffAsset_LeaseAsset]
GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_RemarketingVendor] FOREIGN KEY([RemarketingVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoffAsset_RemarketingVendor]
GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_RepossessionAgent] FOREIGN KEY([RepossessionAgentId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoffAsset_RepossessionAgent]
GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_TerminationReasonConfig] FOREIGN KEY([TerminationReasonConfigId])
REFERENCES [dbo].[TerminationReasonConfigs] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoffAsset_TerminationReasonConfig]
GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_UpfrontTaxAssessedAssetLocation] FOREIGN KEY([UpfrontTaxAssessedAssetLocationId])
REFERENCES [dbo].[AssetLocations] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoffAsset_UpfrontTaxAssessedAssetLocation]
GO
ALTER TABLE [dbo].[PayoffAssets]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_UpfrontTaxAssessedCustomerLocation] FOREIGN KEY([UpfrontTaxAssessedCustomerLocationId])
REFERENCES [dbo].[ContractCustomerLocations] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssets] CHECK CONSTRAINT [EPayoffAsset_UpfrontTaxAssessedCustomerLocation]
GO
