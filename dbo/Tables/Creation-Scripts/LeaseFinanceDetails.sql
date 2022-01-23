SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseFinanceDetails](
	[Id] [bigint] NOT NULL,
	[InterimPaymentFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[InterimPaymentFrequencyDays] [int] NOT NULL,
	[InterimAssessmentMethod] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[InterimInterestBillingType] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[InterimInterestFrequencyStartDate] [date] NULL,
	[InterimInterestDayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[CreateSoftAssetsForInterimInterest] [bit] NOT NULL,
	[InterimRentBillingType] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[IsInterimRentInAdvance] [bit] NOT NULL,
	[InterimRentFrequencyStartDate] [date] NULL,
	[InterimRentDayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[CreateSoftAssetsForInterimRent] [bit] NOT NULL,
	[DueDay] [int] NOT NULL,
	[RentAccrualDate] [date] NULL,
	[CommencementDate] [date] NULL,
	[FrequencyStartDate] [date] NULL,
	[NumberOfPayments] [int] NOT NULL,
	[IsAdvance] [bit] NOT NULL,
	[NumberOfInceptionPayments] [int] NOT NULL,
	[InceptionPayment_Amount] [decimal](16, 2) NOT NULL,
	[InceptionPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DownPayment_Amount] [decimal](16, 2) NULL,
	[DownPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DownPaymentDueDate] [date] NULL,
	[DayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[IsRegularPaymentStream] [bit] NOT NULL,
	[PaymentFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[PaymentFrequencyDays] [int] NOT NULL,
	[MaturityDate] [date] NULL,
	[TermInMonths] [decimal](10, 6) NULL,
	[Markup_Amount] [decimal](16, 2) NOT NULL,
	[Markup_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterimRent_Amount] [decimal](16, 2) NOT NULL,
	[InterimRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Rent_Amount] [decimal](16, 2) NOT NULL,
	[Rent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerExpectedResidual_Amount] [decimal](16, 2) NOT NULL,
	[CustomerExpectedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BookedResidual_Amount] [decimal](16, 2) NOT NULL,
	[BookedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerGuaranteedResidual_Amount] [decimal](16, 2) NOT NULL,
	[CustomerGuaranteedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ThirdPartyGuaranteedResidual_Amount] [decimal](16, 2) NOT NULL,
	[ThirdPartyGuaranteedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ResidualValueInsurance_Amount] [decimal](16, 2) NOT NULL,
	[ResidualValueInsurance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsPricingYieldExtreme] [bit] NOT NULL,
	[ManagementYield] [decimal](28, 18) NOT NULL,
	[IsManagementYieldExtreme] [bit] NOT NULL,
	[IsTotalYieldExtreme] [bit] NOT NULL,
	[PurchaseRVIForCapitalLeaseTreatment] [bit] NOT NULL,
	[LastExtensionARUpdateRunDate] [date] NULL,
	[LastSupplementalARUpdateRunDate] [date] NULL,
	[PurchaseOption] [nvarchar](32) COLLATE Latin1_General_CI_AS NULL,
	[LessorYield] [decimal](28, 18) NOT NULL,
	[IsLessorYieldExtreme] [bit] NOT NULL,
	[ClassificationYield] [decimal](28, 18) NOT NULL,
	[IsClassificationYieldExtreme] [bit] NOT NULL,
	[PostDate] [date] NULL,
	[ClassificationContractType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[LeaseContractType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[CostOfFunds] [decimal](9, 6) NOT NULL,
	[TotalEconomicLifeInMonths] [int] NOT NULL,
	[RemainingEconomicLifeInMonths] [int] NOT NULL,
	[IsBargainPurchaseOption] [bit] NOT NULL,
	[IsTransferOfOwnership] [bit] NOT NULL,
	[PreRVINinetyPercentTestResult] [decimal](10, 6) NOT NULL,
	[PreRVINinetyPercentTestPresentValue_Amount] [decimal](16, 2) NOT NULL,
	[PreRVINinetyPercentTestPresentValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NinetyPercentTestResult] [decimal](10, 6) NOT NULL,
	[NinetyPercentTestPresentValue_Amount] [decimal](16, 2) NOT NULL,
	[NinetyPercentTestPresentValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalEconomicLifeTestResult] [decimal](10, 6) NOT NULL,
	[SalesTypeLeaseGrossProfit_Amount] [decimal](16, 2) NOT NULL,
	[SalesTypeLeaseGrossProfit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsClassificationTestDone] [bit] NOT NULL,
	[IsCalculationDoneAsOfSalesType] [bit] NOT NULL,
	[RateCardRate] [decimal](9, 5) NULL,
	[RateExpirationDate] [date] NULL,
	[ApprovalDateSwapRate] [decimal](9, 5) NULL,
	[ApprovalNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[VendorExceptionApprovalNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[VendorRateBuyDownAmount_Amount] [decimal](16, 2) NOT NULL,
	[VendorRateBuyDownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BankYieldSpread] [decimal](28, 18) NOT NULL,
	[TotalYield] [decimal](28, 18) NOT NULL,
	[InternalYield] [decimal](28, 18) NOT NULL,
	[IsInternalYieldExtreme] [bit] NOT NULL,
	[IsYieldComputed] [bit] NOT NULL,
	[IsManagementYieldComputed] [bit] NOT NULL,
	[IsTaxLease] [bit] NOT NULL,
	[NetInvestment_Amount] [decimal](16, 2) NOT NULL,
	[NetInvestment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsFloatRateLease] [bit] NOT NULL,
	[CreateSoftAssetsForCappedSalesTax] [bit] NOT NULL,
	[CapitalizeUpfrontSalesTax] [bit] NOT NULL,
	[IsOverTermLease] [bit] NOT NULL,
	[BillOTPForSoftAssets] [bit] NOT NULL,
	[NumberOfOverTermPayments] [int] NOT NULL,
	[OTPPaymentFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[OTPPaymentFrequencyUnit] [int] NULL,
	[OTPRent_Amount] [decimal](16, 2) NOT NULL,
	[OTPRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SupplementalRent_Amount] [decimal](16, 2) NOT NULL,
	[SupplementalRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsSupplementalAdvance] [bit] NOT NULL,
	[SupplementalFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[SupplementalFrequencyUnit] [int] NULL,
	[SupplementalGracePeriod] [int] NOT NULL,
	[DeliverViaMail] [bit] NOT NULL,
	[DeliverViaEmail] [bit] NOT NULL,
	[SendEmailNotificationTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[SendCCEmailNotificationTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsLessorNotice] [bit] NOT NULL,
	[IsLesseeNotice] [bit] NOT NULL,
	[MaturityDateBasis] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[NoticeBasis] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[MaxNoticePeriod] [int] NOT NULL,
	[MinNoticePeriod] [int] NOT NULL,
	[RemarketingResponsibility] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[OfferLetterAdditionalDays] [int] NOT NULL,
	[FollowUpLeadDays] [int] NOT NULL,
	[CustomerNotificationLeadDays] [int] NOT NULL,
	[InvestorNotificationLeadDays] [int] NOT NULL,
	[LessorNoticePeriod] [int] NOT NULL,
	[DeferredTaxBalance_Amount] [decimal](16, 2) NOT NULL,
	[DeferredTaxBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsOTPRegularPaymentStream] [bit] NOT NULL,
	[OTPRentPreference] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[TerminationNoticeReceived] [bit] NOT NULL,
	[TerminationNoticeReceivedOn] [date] NULL,
	[TerminationNoticeEffectiveDate] [date] NULL,
	[IsOTPScheduled] [bit] NOT NULL,
	[FloridaStampTax_Amount] [decimal](16, 2) NULL,
	[FloridaStampTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TennesseeIndebtednessTax_Amount] [decimal](16, 2) NULL,
	[TennesseeIndebtednessTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TNIndebtednessDiligenzFee_Amount] [decimal](16, 2) NULL,
	[TNIndebtednessDiligenzFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CapitalizedSalesTaxPayment_Amount] [decimal](16, 2) NOT NULL,
	[CapitalizedSalesTaxPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalStreamTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[TotalStreamTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalUpfrontTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[TotalUpfrontTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerFacingYield] [decimal](28, 18) NOT NULL,
	[InvestmentModifiedAfterPayment] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ClassificationOverriddenById] [bigint] NULL,
	[InterimInterestReceivableCodeId] [bigint] NULL,
	[InterimRentReceivableCodeId] [bigint] NULL,
	[FixedTermReceivableCodeId] [bigint] NULL,
	[FloatRateARReceivableCodeId] [bigint] NULL,
	[OTPReceivableCodeId] [bigint] NULL,
	[SupplementalReceivableCodeId] [bigint] NULL,
	[InterimInterestIncomeGLTemplateId] [bigint] NULL,
	[InterimRentIncomeGLTemplateId] [bigint] NULL,
	[LeaseBookingGLTemplateId] [bigint] NULL,
	[LeaseIncomeGLTemplateId] [bigint] NULL,
	[PropertyTaxReceivableCodeId] [bigint] NULL,
	[FloatIncomeGLTemplateId] [bigint] NULL,
	[OTPIncomeGLTemplateId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[DeferredTaxGLTemplateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[RegularPaymentAmount_Amount] [decimal](16, 2) NOT NULL,
	[RegularPaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerTermInMonths] [int] NULL,
	[CreateInvoiceForAdvanceRental] [bit] NOT NULL,
	[BillInterimAsOf] [nvarchar](35) COLLATE Latin1_General_CI_AS NULL,
	[TaxDepExpenseGLTemplateId] [bigint] NULL,
	[TaxAssetSetupGLTemplateId] [bigint] NULL,
	[TaxDepDisposalTemplateId] [bigint] NULL,
	[EligibleForResidualValueInsurance] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[InvestmentModifiedAfterPaymentForSpecificCostAdj] [bit] NOT NULL,
	[FMV_Amount] [decimal](16, 2) NOT NULL,
	[FMV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[MaturityPayment_Amount] [decimal](16, 2) NOT NULL,
	[MaturityPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsSpecializedUseAssets] [bit] NOT NULL,
	[LessorYieldLeaseAsset] [decimal](28, 18) NOT NULL,
	[LessorYieldFinanceAsset] [decimal](28, 18) NOT NULL,
	[NinetyPercent5ATestResult] [decimal](10, 6) NOT NULL,
	[NinetyPercent5BTestResult] [decimal](10, 6) NOT NULL,
	[NinetyPercentTestPresentValue5A_Amount] [decimal](16, 2) NOT NULL,
	[NinetyPercentTestPresentValue5A_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NinetyPercentTestPresentValue5B_Amount] [decimal](16, 2) NOT NULL,
	[NinetyPercentTestPresentValue5B_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ClassificationYield5A] [decimal](28, 18) NOT NULL,
	[ClassificationYield5B] [decimal](28, 18) NOT NULL,
	[DeferredSellingProfit_Amount] [decimal](16, 2) NOT NULL,
	[DeferredSellingProfit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NinetyPercent5ATestResultPassed] [bit] NOT NULL,
	[NinetyPercent5BTestResultPassed] [bit] NOT NULL,
	[IsClassificationYield5AExtreme] [bit] NOT NULL,
	[IsClassificationYield5BExtreme] [bit] NOT NULL,
	[YieldCalculationParametersChanged] [bit] NOT NULL,
	[IsLessorYieldLeaseAssetExtreme] [bit] NOT NULL,
	[IsLessorYieldFinanceAssetExtreme] [bit] NOT NULL,
	[ProfitLossStatus] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[NinetyPercentTestResultPassed] [bit] NOT NULL,
	[StepPercentage] [decimal](10, 6) NULL,
	[StepPeriod] [int] NULL,
	[StubAdjustment] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[StepPaymentStartDate] [date] NULL,
	[IsStepPayment] [bit] NOT NULL,
	[RecalculateInterestonReprice] [bit] NOT NULL,
	[RestructureOnFloatRateChange] [bit] NOT NULL,
	[PercentageToVendor] [decimal](18, 8) NOT NULL,
	[InterimRentPayableCodeId] [bigint] NULL,
	[OTPSharingTemplateId] [bigint] NULL,
	[OTPRentPayableCodeId] [bigint] NULL,
	[InterimRentPayableWithholdingTaxRate] [decimal](5, 2) NULL,
	[OTPRentPayableWithholdingTaxRate] [decimal](5, 2) NULL,
	[CompoundingFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[EffectiveAnnualRate] [decimal](28, 18) NOT NULL,
	[IsDownpaymentIncludesTax] [bit] NOT NULL,
	[VATDownPayment_Amount] [decimal](16, 2) NOT NULL,
	[VATDownPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalDownPayment_Amount] [decimal](16, 2) NOT NULL,
	[TotalDownPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FinancedAmountExclVAT_Amount] [decimal](16, 2) NULL,
	[FinancedAmountExclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AdvancetoDealer_Amount] [decimal](16, 2) NULL,
	[AdvancetoDealer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsBuybackGuaranteebyVendor] [bit] NOT NULL,
	[DownPaymentPercentageId] [bigint] NOT NULL,
	[OverrideReason] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[NetTermBasis] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetTerms] [int] NOT NULL,
	[IsOTPParametersChanged] [bit] NOT NULL,
	[IsPromissoryNote] [bit] NULL,
	[PromissoryNote_Amount] [decimal](16, 2) NULL,
	[PromissoryNote_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsApplicable] [bit] NULL,
	[DateOfIncorporation] [date] NULL,
	[ExpirationDate] [date] NULL,
	[IsReleased] [bit] NULL,
	[CashGuaranteesAmount_Amount] [decimal](16, 2) NULL,
	[CashGuaranteesAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_LeaseFinanceDetail] FOREIGN KEY([Id])
REFERENCES [dbo].[LeaseFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinance_LeaseFinanceDetail]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_ClassificationOverriddenBy] FOREIGN KEY([ClassificationOverriddenById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_ClassificationOverriddenBy]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_DeferredTaxGLTemplate] FOREIGN KEY([DeferredTaxGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_DeferredTaxGLTemplate]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_DownPaymentPercentage] FOREIGN KEY([DownPaymentPercentageId])
REFERENCES [dbo].[QuoteDownPayments] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_DownPaymentPercentage]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_FixedTermReceivableCode] FOREIGN KEY([FixedTermReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_FixedTermReceivableCode]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_FloatIncomeGLTemplate] FOREIGN KEY([FloatIncomeGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_FloatIncomeGLTemplate]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_FloatRateARReceivableCode] FOREIGN KEY([FloatRateARReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_FloatRateARReceivableCode]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_GLJournal]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_InterimInterestIncomeGLTemplate] FOREIGN KEY([InterimInterestIncomeGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_InterimInterestIncomeGLTemplate]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_InterimInterestReceivableCode] FOREIGN KEY([InterimInterestReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_InterimInterestReceivableCode]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_InterimRentIncomeGLTemplate] FOREIGN KEY([InterimRentIncomeGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_InterimRentIncomeGLTemplate]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_InterimRentPayableCode] FOREIGN KEY([InterimRentPayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_InterimRentPayableCode]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_InterimRentReceivableCode] FOREIGN KEY([InterimRentReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_InterimRentReceivableCode]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_LeaseBookingGLTemplate] FOREIGN KEY([LeaseBookingGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_LeaseBookingGLTemplate]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_LeaseIncomeGLTemplate] FOREIGN KEY([LeaseIncomeGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_LeaseIncomeGLTemplate]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_OTPIncomeGLTemplate] FOREIGN KEY([OTPIncomeGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_OTPIncomeGLTemplate]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_OTPReceivableCode] FOREIGN KEY([OTPReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_OTPReceivableCode]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_OTPRentPayableCode] FOREIGN KEY([OTPRentPayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_OTPRentPayableCode]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_OTPSharingTemplate] FOREIGN KEY([OTPSharingTemplateId])
REFERENCES [dbo].[OTPSharingTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_OTPSharingTemplate]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_PropertyTaxReceivableCode] FOREIGN KEY([PropertyTaxReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_PropertyTaxReceivableCode]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_SupplementalReceivableCode] FOREIGN KEY([SupplementalReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_SupplementalReceivableCode]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_TaxAssetSetupGLTemplate] FOREIGN KEY([TaxAssetSetupGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_TaxAssetSetupGLTemplate]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_TaxDepDisposalTemplate] FOREIGN KEY([TaxDepDisposalTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_TaxDepDisposalTemplate]
GO
ALTER TABLE [dbo].[LeaseFinanceDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_TaxDepExpenseGLTemplate] FOREIGN KEY([TaxDepExpenseGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_TaxDepExpenseGLTemplate]
GO
