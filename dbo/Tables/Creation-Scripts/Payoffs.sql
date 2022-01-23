SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Payoffs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[QuoteName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[FullPayoff] [bit] NOT NULL,
	[PayoffAtInception] [bit] NOT NULL,
	[Status] [nvarchar](25) COLLATE Latin1_General_CI_AS NOT NULL,
	[GoodThroughDate] [date] NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[PayoffEffectiveDate] [date] NULL,
	[Settlement] [bit] NOT NULL,
	[Report1099C] [bit] NOT NULL,
	[ApplyAtAssetLevel] [bit] NOT NULL,
	[PayoffDiscountRate] [decimal](8, 4) NULL,
	[SuggestedPayoffAmount_Amount] [decimal](16, 2) NOT NULL,
	[SuggestedPayoffAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayoffAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayoffAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayoffWeightageAttribute] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[BuyoutDiscountRate] [decimal](8, 4) NULL,
	[BuyoutWeightageAttribute] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[SuggestedBuyoutAmount_Amount] [decimal](16, 2) NOT NULL,
	[SuggestedBuyoutAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BuyoutAmount_Amount] [decimal](16, 2) NOT NULL,
	[BuyoutAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayoffAssetStatus] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[PayoffAssetSubStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[AssetValuation_Amount] [decimal](16, 2) NOT NULL,
	[AssetValuation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OLV_Amount] [decimal](16, 2) NOT NULL,
	[OLV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetValuationWeightageAttribute] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[OLVWeightageAttribute] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[DueDate] [date] NULL,
	[StopInvoicingFutureRentals] [bit] NOT NULL,
	[IncludeOutstandingCharges] [bit] NOT NULL,
	[PayoffInvoicePreference] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[BuyoutInvoicePreference] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[EstimatedPropertyTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[EstimatedPropertyTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayoffInvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NULL,
	[AccountingDate] [date] NULL,
	[OriginalChargeoffAmount_Amount] [decimal](16, 2) NOT NULL,
	[OriginalChargeoffAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ChargeoffBalance_Amount] [decimal](16, 2) NOT NULL,
	[ChargeoffBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsSystemGenerated] [bit] NOT NULL,
	[SummaryComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsParametersChanged] [bit] NOT NULL,
	[IsPaymentScheduleGenerated] [bit] NOT NULL,
	[PrePayoffPricingInterestRate] [decimal](12, 6) NULL,
	[PostPayoffPricingInterestRate] [decimal](12, 6) NULL,
	[AssetFinancialValuesComputed] [bit] NOT NULL,
	[IsAssetFinancialValueParametersChanged] [bit] NOT NULL,
	[BlendedFinancialValuesComputed] [bit] NOT NULL,
	[NetInvestmentWithBlended_Amount] [decimal](16, 2) NOT NULL,
	[NetInvestmentWithBlended_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[GrossWriteDown_Amount] [decimal](16, 2) NOT NULL,
	[GrossWriteDown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetWriteDown_Amount] [decimal](16, 2) NOT NULL,
	[NetWriteDown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsPaidOffInInstallPhase] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[LeasePaymentScheduleId] [bigint] NULL,
	[BillToCustomerId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[PayoffReceivableCodeId] [bigint] NULL,
	[BuyoutReceivableCodeId] [bigint] NULL,
	[PropertyTaxEscrowReceivableCodeId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[PayoffGLTemplateId] [bigint] NULL,
	[AssetBookValueAdjustmentGLTemplateId] [bigint] NULL,
	[NBVImpairmentGLTemplateId] [bigint] NULL,
	[WritedownReceivableCodeId] [bigint] NULL,
	[WritedownGLTemplateId] [bigint] NULL,
	[TerminationOptionId] [bigint] NULL,
	[InventoryBookDepGLTemplateId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ShipFromId] [bigint] NULL,
	[AddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Zip] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[StateId] [bigint] NULL,
	[FrieghtBillToId] [bigint] NULL,
	[EMail] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[FullName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[MobilePhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[PhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[PickupDate] [date] NULL,
	[TaxDepDisposalTemplateId] [bigint] NULL,
	[PayoffRequestPhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[PayoffRequestEMail] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[QuoteNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetHoldingStatusChangeId] [bigint] NULL,
	[ReceiptHierarchyTemplateId] [bigint] NULL,
	[ApplySecurityDeposit] [bit] NOT NULL,
	[ReversalGLJournalId] [bigint] NULL,
	[ReversalPostDate] [date] NULL,
	[FMV_Amount] [decimal](16, 2) NOT NULL,
	[FMV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPRent_Amount] [decimal](16, 2) NOT NULL,
	[OTPRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[QuoteType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[MultiplePricingOption] [bit] NOT NULL,
	[IsPayoffTemplateParametersChanged] [bit] NOT NULL,
	[DailyFinanceAsOfDate] [date] NULL,
	[PayOffTemplateId] [bigint] NULL,
	[PayOffTemplateTerminationTypeId] [bigint] NULL,
	[IsPayoffPricingOptionsPopulated] [bit] NOT NULL,
	[IsCreatedFromVendorPortal] [bit] NOT NULL,
	[TradeupFeeAmount] [decimal](16, 2) NOT NULL,
	[TradeUpFeeReceivableCodeId] [bigint] NULL,
	[ExternalReferenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PurchaseOption] [nvarchar](32) COLLATE Latin1_General_CI_AS NULL,
	[TotalEconomicLifeInMonths] [int] NOT NULL,
	[RemainingEconomicLifeInMonths] [int] NOT NULL,
	[IsBargainPurchaseOption] [bit] NOT NULL,
	[IsTransferOfOwnership] [bit] NOT NULL,
	[IsSpecializedUseAssets] [bit] NOT NULL,
	[TotalEconomicLifeTestResult] [decimal](10, 6) NOT NULL,
	[NinetyPercentTestPresentValue_Amount] [decimal](16, 2) NOT NULL,
	[NinetyPercentTestPresentValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NinetyPercentTestResult] [decimal](10, 6) NOT NULL,
	[NinetyPercentTestResultPassed] [bit] NOT NULL,
	[NinetyPercentTestPresentValue5A_Amount] [decimal](16, 2) NOT NULL,
	[NinetyPercentTestPresentValue5A_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NinetyPercentTestPresentValue5B_Amount] [decimal](16, 2) NOT NULL,
	[NinetyPercentTestPresentValue5B_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NinetyPercent5ATestResultPassed] [bit] NOT NULL,
	[NinetyPercent5BTestResultPassed] [bit] NOT NULL,
	[NinetyPercent5ATestResult] [decimal](10, 6) NOT NULL,
	[NinetyPercent5BTestResult] [decimal](10, 6) NOT NULL,
	[ClassificationContractType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[LessorYield] [decimal](28, 18) NOT NULL,
	[LessorYieldLeaseAsset] [decimal](28, 18) NOT NULL,
	[LessorYieldFinanceAsset] [decimal](28, 18) NOT NULL,
	[ClassificationYield] [decimal](28, 18) NOT NULL,
	[ClassificationYield5A] [decimal](28, 18) NOT NULL,
	[ClassificationYield5B] [decimal](28, 18) NOT NULL,
	[IsClassificationTestDone] [bit] NOT NULL,
	[ClassificationTestParametersChanged] [bit] NOT NULL,
	[IsLessorYieldExtreme] [bit] NOT NULL,
	[IsLessorYieldFinanceAssetExtreme] [bit] NOT NULL,
	[IsLessorYieldLeaseAssetExtreme] [bit] NOT NULL,
	[IsClassificationYieldExtreme] [bit] NOT NULL,
	[IsClassificationYield5AExtreme] [bit] NOT NULL,
	[IsClassificationYield5BExtreme] [bit] NOT NULL,
	[IsYieldComputed] [bit] NOT NULL,
	[YieldCalculationParametersChanged] [bit] NOT NULL,
	[AutoPayoffTemplateId] [bigint] NULL,
	[IsAssetBasedEstimatedPropertyTax] [bit] NOT NULL,
	[IsGLConsolidated] [bit] NOT NULL,
	[EstimatedPropertyTaxVATAmount_Amount] [decimal](16, 2) NOT NULL,
	[EstimatedPropertyTaxVATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TradeupFeeVATAmount_Amount] [decimal](16, 2) NOT NULL,
	[TradeupFeeVATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayoffVATAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayoffVATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BuyoutVATAmount_Amount] [decimal](16, 2) NOT NULL,
	[BuyoutVATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsVATAssessed] [bit] NOT NULL,
	[IsCreatedFromCustomerPortal] [bit] NOT NULL,
PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_AssetBookValueAdjustmentGLTemplate] FOREIGN KEY([AssetBookValueAdjustmentGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_AssetBookValueAdjustmentGLTemplate]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_AssetHoldingStatusChange] FOREIGN KEY([AssetHoldingStatusChangeId])
REFERENCES [dbo].[AssetHoldingStatusChanges] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_AssetHoldingStatusChange]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_AutoPayoffTemplate] FOREIGN KEY([AutoPayoffTemplateId])
REFERENCES [dbo].[AutoPayoffTemplates] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_AutoPayoffTemplate]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_BillTo]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_BillToCustomer] FOREIGN KEY([BillToCustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_BillToCustomer]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_BuyoutReceivableCode] FOREIGN KEY([BuyoutReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_BuyoutReceivableCode]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_FrieghtBillTo] FOREIGN KEY([FrieghtBillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_FrieghtBillTo]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_GLJournal]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_InventoryBookDepGLTemplate] FOREIGN KEY([InventoryBookDepGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_InventoryBookDepGLTemplate]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_LeaseFinance] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_LeaseFinance]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_LeasePaymentSchedule] FOREIGN KEY([LeasePaymentScheduleId])
REFERENCES [dbo].[LeasePaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_LeasePaymentSchedule]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_NBVImpairmentGLTemplate] FOREIGN KEY([NBVImpairmentGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_NBVImpairmentGLTemplate]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_PayoffGLTemplate] FOREIGN KEY([PayoffGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_PayoffGLTemplate]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_PayoffReceivableCode] FOREIGN KEY([PayoffReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_PayoffReceivableCode]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_PayOffTemplate] FOREIGN KEY([PayOffTemplateId])
REFERENCES [dbo].[PayOffTemplates] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_PayOffTemplate]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_PayOffTemplateTerminationType] FOREIGN KEY([PayOffTemplateTerminationTypeId])
REFERENCES [dbo].[PayOffTemplateTerminationTypes] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_PayOffTemplateTerminationType]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_PropertyTaxEscrowReceivableCode] FOREIGN KEY([PropertyTaxEscrowReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_PropertyTaxEscrowReceivableCode]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_ReceiptHierarchyTemplate] FOREIGN KEY([ReceiptHierarchyTemplateId])
REFERENCES [dbo].[ReceiptHierarchyTemplates] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_ReceiptHierarchyTemplate]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_RemitTo]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_ReversalGLJournal] FOREIGN KEY([ReversalGLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_ReversalGLJournal]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_ShipFrom] FOREIGN KEY([ShipFromId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_ShipFrom]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_State]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_TaxDepDisposalTemplate] FOREIGN KEY([TaxDepDisposalTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_TaxDepDisposalTemplate]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_TerminationOption] FOREIGN KEY([TerminationOptionId])
REFERENCES [dbo].[PayoffTerminationOptions] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_TerminationOption]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_TradeUpFeeReceivableCode] FOREIGN KEY([TradeUpFeeReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_TradeUpFeeReceivableCode]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_WritedownGLTemplate] FOREIGN KEY([WritedownGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_WritedownGLTemplate]
GO
ALTER TABLE [dbo].[Payoffs]  WITH CHECK ADD  CONSTRAINT [EPayoff_WritedownReceivableCode] FOREIGN KEY([WritedownReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[Payoffs] CHECK CONSTRAINT [EPayoff_WritedownReceivableCode]
GO
