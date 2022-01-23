SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditApplicationPricingDetails](
	[Id] [bigint] NOT NULL,
	[Term] [int] NOT NULL,
	[CreditApplicationAmount_Amount] [decimal](16, 2) NULL,
	[CreditApplicationAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[QuotedRent_Amount] [decimal](16, 2) NULL,
	[QuotedRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[QuoteExpirationDate] [date] NULL,
	[Frequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[Advance] [bit] NOT NULL,
	[RequestEOTOption] [nvarchar](32) COLLATE Latin1_General_CI_AS NULL,
	[RequestedResidualPercentage] [decimal](5, 2) NULL,
	[RequestedResidualAmount_Amount] [decimal](16, 2) NULL,
	[RequestedResidualAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[EstimatedBalloonAmount_Amount] [decimal](16, 2) NULL,
	[EstimatedBalloonAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CurrencyId] [bigint] NOT NULL,
	[RequestedPromotionId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsRegularPaymentStream] [bit] NOT NULL,
	[QuoteBasedPricing] [bit] NOT NULL,
	[QuoteId] [bigint] NULL,
	[ExpectedDisbursementDate] [date] NULL,
	[AssetCost_Amount] [decimal](16, 2) NULL,
	[AssetCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AdminFee_Amount] [decimal](16, 2) NULL,
	[AdminFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TradeIn_Amount] [decimal](16, 2) NULL,
	[TradeIn_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DownPayment_Amount] [decimal](16, 2) NULL,
	[DownPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
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
	[CalculatedPaymentAmount_Amount] [decimal](16, 2) NULL,
	[CalculatedPaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[UsageCondition] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[ModelYear] [decimal](4, 0) NULL,
	[TotalCost_Amount] [decimal](16, 2) NULL,
	[TotalCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ImportEquipmentDetailsatHeader] [bit] NOT NULL,
	[CanUsePricingEngine] [bit] NOT NULL,
	[StepPercentage] [decimal](10, 6) NULL,
	[StepPeriod] [int] NULL,
	[StubAdjustment] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[StepPaymentStartDate] [date] NULL,
	[IsStepPayment] [bit] NOT NULL,
	[DayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ProgramRateCardRate] [decimal](10, 6) NULL,
	[ProgramRateCardYield] [decimal](10, 6) NULL,
	[ProgramAssetTypeId] [bigint] NULL,
	[BaseRate] [decimal](10, 6) NULL,
	[DueDay] [int] NOT NULL,
	[CompoundingFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[IsDownpaymentIncludesTax] [bit] NOT NULL,
	[VATDownPayment_Amount] [decimal](16, 2) NOT NULL,
	[VATDownPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalDownPayment_Amount] [decimal](16, 2) NOT NULL,
	[TotalDownPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[QuotedTax_Amount] [decimal](16, 2) NULL,
	[QuotedTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[EffectiveAnnualRate] [decimal](28, 18) NOT NULL,
	[AdvanceToDealer_Amount] [decimal](16, 2) NULL,
	[AdvanceToDealer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InterestRate] [decimal](5, 2) NOT NULL,
	[APR] [decimal](5, 2) NULL,
	[IsBuybackGuaranteebyVendor] [bit] NULL,
	[NoOfPayments] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[QuoteLeaseTypeId] [bigint] NOT NULL,
	[DownPaymentPercentageId] [bigint] NULL,
	[IsManualInterestMargin] [bit] NOT NULL,
	[InterestConfiguration] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_CreditApplicationPricingDetail] FOREIGN KEY([Id])
REFERENCES [dbo].[CreditApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails] CHECK CONSTRAINT [ECreditApplication_CreditApplicationPricingDetail]
GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationPricingDetail_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails] CHECK CONSTRAINT [ECreditApplicationPricingDetail_Currency]
GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationPricingDetail_DownPaymentPercentage] FOREIGN KEY([DownPaymentPercentageId])
REFERENCES [dbo].[QuoteDownPayments] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails] CHECK CONSTRAINT [ECreditApplicationPricingDetail_DownPaymentPercentage]
GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationPricingDetail_ProgramAssetType] FOREIGN KEY([ProgramAssetTypeId])
REFERENCES [dbo].[ProgramAssetTypes] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails] CHECK CONSTRAINT [ECreditApplicationPricingDetail_ProgramAssetType]
GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationPricingDetail_Quote] FOREIGN KEY([QuoteId])
REFERENCES [dbo].[Quotes] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails] CHECK CONSTRAINT [ECreditApplicationPricingDetail_Quote]
GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationPricingDetail_QuoteLeaseType] FOREIGN KEY([QuoteLeaseTypeId])
REFERENCES [dbo].[QuoteLeaseTypes] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails] CHECK CONSTRAINT [ECreditApplicationPricingDetail_QuoteLeaseType]
GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationPricingDetail_RequestedPromotion] FOREIGN KEY([RequestedPromotionId])
REFERENCES [dbo].[ProgramPromotions] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationPricingDetails] CHECK CONSTRAINT [ECreditApplicationPricingDetail_RequestedPromotion]
GO
