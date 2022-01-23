SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditApprovedStructures](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Term] [decimal](10, 6) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsProgressFunding] [bit] NOT NULL,
	[IsIndexBasedProgressFunding] [bit] NOT NULL,
	[ProgressFundingIndexAsofDate] [date] NULL,
	[ProgressFundingBaseRate] [decimal](10, 6) NULL,
	[ProgressFundingSpread] [decimal](10, 6) NULL,
	[ProgressFundingFloorRate] [decimal](10, 6) NULL,
	[ProgressFundingCeilingRate] [decimal](10, 6) NULL,
	[ProgressFundingTotalRate] [decimal](10, 6) NULL,
	[ProgressFundingDescription] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[IsIndexBased] [bit] NOT NULL,
	[IndexAsofDate] [date] NULL,
	[BaseRate] [decimal](10, 6) NOT NULL,
	[FloorRate] [decimal](10, 6) NOT NULL,
	[CeilingRate] [decimal](10, 6) NOT NULL,
	[Spread] [decimal](10, 6) NOT NULL,
	[TotalRate] [decimal](10, 6) NOT NULL,
	[IsAdvance] [bit] NOT NULL,
	[PaymentFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[NumberofPayments] [int] NOT NULL,
	[ExpectedCommencementDate] [date] NULL,
	[VendorSubsidy_Amount] [decimal](16, 2) NOT NULL,
	[VendorSubsidy_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EstimatedBalloonAmount_Amount] [decimal](16, 2) NOT NULL,
	[EstimatedBalloonAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Revolving] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[IrregularFrequencyDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsSaleLeaseback] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DealProductTypeId] [bigint] NULL,
	[PricingBaseIndexId] [bigint] NULL,
	[ProgressFundingBaseIndexId] [bigint] NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustomerTerm] [int] NULL,
	[IsRegularPaymentStream] [bit] NOT NULL,
	[DealTypeId] [bigint] NULL,
	[ProgramIndicatorConfigId] [bigint] NULL,
	[AssetCost_Amount] [decimal](16, 2) NULL,
	[AssetCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AdminFee_Amount] [decimal](16, 2) NULL,
	[AdminFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TradeIn_Amount] [decimal](16, 2) NULL,
	[TradeIn_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DownPayment_Amount] [decimal](16, 2) NOT NULL,
	[DownPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Refinance_Amount] [decimal](16, 2) NULL,
	[Refinance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[GSTorHST_Amount] [decimal](16, 2) NULL,
	[GSTorHST_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TradeUp_Amount] [decimal](16, 2) NULL,
	[TradeUp_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PSTorQST_Amount] [decimal](16, 2) NULL,
	[PSTorQST_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[OtherCosts_Amount] [decimal](16, 2) NULL,
	[OtherCosts_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[OtherCredits_Amount] [decimal](16, 2) NULL,
	[OtherCredits_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ForeignBuyouts_Amount] [decimal](16, 2) NULL,
	[ForeignBuyouts_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Software_Amount] [decimal](16, 2) NULL,
	[Software_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ServicesOrSoftcosts_Amount] [decimal](16, 2) NULL,
	[ServicesOrSoftcosts_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[VendorRateCardRate] [decimal](10, 6) NOT NULL,
	[VendorRateCardYield] [decimal](10, 6) NOT NULL,
	[NumberOfInceptionPayments] [int] NOT NULL,
	[InceptionPayment_Amount] [decimal](16, 2) NOT NULL,
	[InceptionPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDay] [int] NOT NULL,
	[FrequencyStartDate] [date] NULL,
	[CustomerExpectedResidual_Amount] [decimal](16, 2) NOT NULL,
	[CustomerExpectedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsFloatRateLease] [bit] NOT NULL,
	[ExpectedMaturityDate] [date] NULL,
	[IsPaymentScheduleParameterChanged] [bit] NOT NULL,
	[IsCustomerFacingRate] [bit] NOT NULL,
	[StepPercentage] [decimal](10, 6) NULL,
	[StepPeriod] [int] NULL,
	[StubAdjustment] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[StepPaymentStartDate] [date] NULL,
	[IsStepPayment] [bit] NOT NULL,
	[CompoundingFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[IsDownPaymentIncludeTax] [bit] NOT NULL,
	[VATDownPayment_Amount] [decimal](16, 2) NOT NULL,
	[VATDownPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalDownPayment_Amount] [decimal](16, 2) NOT NULL,
	[TotalDownPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsVATAssessedForPayable] [bit] NOT NULL,
	[IsVATAssessedForReceivable] [bit] NOT NULL,
	[EffectiveAnnualRate] [decimal](28, 18) NOT NULL,
	[PricingOption] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[InceptionRentFactor] [decimal](18, 8) NOT NULL,
	[RentFactor] [decimal](18, 8) NOT NULL,
	[Rent_Amount] [decimal](16, 2) NOT NULL,
	[Rent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerExpectedResidualFactor] [decimal](18, 8) NOT NULL,
	[GuaranteedResidualFactor] [decimal](18, 8) NOT NULL,
	[GuaranteedResidual_Amount] [decimal](16, 2) NOT NULL,
	[GuaranteedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ResidualatRisk_Amount] [decimal](16, 2) NOT NULL,
	[ResidualatRisk_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsResidualSharing] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditApprovedStructures]  WITH CHECK ADD  CONSTRAINT [ECreditApprovedStructure_DealProductType] FOREIGN KEY([DealProductTypeId])
REFERENCES [dbo].[DealProductTypes] ([Id])
GO
ALTER TABLE [dbo].[CreditApprovedStructures] CHECK CONSTRAINT [ECreditApprovedStructure_DealProductType]
GO
ALTER TABLE [dbo].[CreditApprovedStructures]  WITH CHECK ADD  CONSTRAINT [ECreditApprovedStructure_DealType] FOREIGN KEY([DealTypeId])
REFERENCES [dbo].[DealTypes] ([Id])
GO
ALTER TABLE [dbo].[CreditApprovedStructures] CHECK CONSTRAINT [ECreditApprovedStructure_DealType]
GO
ALTER TABLE [dbo].[CreditApprovedStructures]  WITH CHECK ADD  CONSTRAINT [ECreditApprovedStructure_PricingBaseIndex] FOREIGN KEY([PricingBaseIndexId])
REFERENCES [dbo].[FloatRateIndexes] ([Id])
GO
ALTER TABLE [dbo].[CreditApprovedStructures] CHECK CONSTRAINT [ECreditApprovedStructure_PricingBaseIndex]
GO
ALTER TABLE [dbo].[CreditApprovedStructures]  WITH CHECK ADD  CONSTRAINT [ECreditApprovedStructure_ProgramIndicatorConfig] FOREIGN KEY([ProgramIndicatorConfigId])
REFERENCES [dbo].[ProgramIndicatorConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditApprovedStructures] CHECK CONSTRAINT [ECreditApprovedStructure_ProgramIndicatorConfig]
GO
ALTER TABLE [dbo].[CreditApprovedStructures]  WITH CHECK ADD  CONSTRAINT [ECreditApprovedStructure_ProgressFundingBaseIndex] FOREIGN KEY([ProgressFundingBaseIndexId])
REFERENCES [dbo].[FloatRateIndexes] ([Id])
GO
ALTER TABLE [dbo].[CreditApprovedStructures] CHECK CONSTRAINT [ECreditApprovedStructure_ProgressFundingBaseIndex]
GO
ALTER TABLE [dbo].[CreditApprovedStructures]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditApprovedStructures] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditApprovedStructures] CHECK CONSTRAINT [ECreditProfile_CreditApprovedStructures]
GO
