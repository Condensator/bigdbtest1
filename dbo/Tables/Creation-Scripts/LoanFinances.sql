SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanFinances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[VersionNumber] [int] NOT NULL,
	[IsApproved] [bit] NOT NULL,
	[IsCurrent] [bit] NOT NULL,
	[Status] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApprovalStatus] [nvarchar](25) COLLATE Latin1_General_CI_AS NOT NULL,
	[ModificationType] [nvarchar](31) COLLATE Latin1_General_CI_AS NOT NULL,
	[CommencementDate] [date] NULL,
	[MaturityDate] [date] NULL,
	[Term] [decimal](10, 6) NULL,
	[NumberOfPayments] [int] NULL,
	[PaymentFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[PaymentNumberOfDays] [int] NULL,
	[LoanAmount_Amount] [decimal](16, 2) NOT NULL,
	[LoanAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DownPayment_Amount] [decimal](16, 2) NULL,
	[DownPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[VendorDownPayment_Amount] [decimal](16, 2) NULL,
	[VendorDownPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DueDay] [int] NULL,
	[FirstPaymentDate] [date] NULL,
	[FloatRateChangeAmortOption] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[InterimBillingType] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[InterimDayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[InterimFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[InterimNumberOfDays] [int] NULL,
	[InterimDueDay] [int] NULL,
	[InterimCompoundingFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[DayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[AccrueThroughDueDate] [bit] NOT NULL,
	[AccrueDayMethod] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[AccrualDay] [int] NULL,
	[CompoundingOption] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[CompoundingFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[IsDailySensitive] [bit] NOT NULL,
	[IsSameAsCash] [bit] NOT NULL,
	[CashEndDate] [date] NULL,
	[PostDate] [date] NULL,
	[IsPaymentScheduleGenerated] [bit] NOT NULL,
	[IsPaymentScheduleModified] [bit] NOT NULL,
	[LastPaymentAmount_Amount] [decimal](16, 2) NOT NULL,
	[LastPaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterimAdjustmentDate] [date] NULL,
	[IsConduit] [bit] NOT NULL,
	[BankQualified] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[HoldingStatus] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[AcquisitionID] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[ContractPurchaseOrderNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsSOPStatus] [bit] NOT NULL,
	[IsSendToGAIC] [bit] NOT NULL,
	[GAICStatus] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[GAICRejectionReason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsEligibleforInterimJob] [bit] NOT NULL,
	[IsAMReviewCompleted] [bit] NOT NULL,
	[IsAMReviewRequired] [bit] NOT NULL,
	[IsPricingParametersChanged] [bit] NOT NULL,
	[IsPaymentScheduleParametersChanged] [bit] NOT NULL,
	[IsFundingApproved] [bit] NOT NULL,
	[IsAccountingApproved] [bit] NOT NULL,
	[ManagementYield] [decimal](28, 18) NOT NULL,
	[VendorExceptionApprovalNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[VendorRateBuyDownAmount_Amount] [decimal](16, 2) NULL,
	[VendorRateBuyDownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsManagementYieldCalculated] [bit] NOT NULL,
	[IsHostedsolution] [bit] NOT NULL,
	[CurrentMaturityDate] [date] NULL,
	[TennesseeIndebtednessTax_Amount] [decimal](16, 2) NULL,
	[TennesseeIndebtednessTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TNIndebtednessDiligenzFee_Amount] [decimal](16, 2) NULL,
	[TNIndebtednessDiligenzFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[FloatRateUpdateRunDate] [date] NULL,
	[IsAssignToRecovery] [bit] NOT NULL,
	[CustomerFacingYield] [decimal](28, 18) NOT NULL,
	[ApprovalDateSwapRate] [decimal](9, 5) NULL,
	[InternalYield] [decimal](28, 18) NOT NULL,
	[IsInternalYieldExtreme] [bit] NOT NULL,
	[BankYieldSpread] [decimal](28, 18) NOT NULL,
	[TotalYield] [decimal](28, 18) NOT NULL,
	[RateCardRate] [decimal](9, 5) NULL,
	[RateExpirationDate] [date] NULL,
	[IsAdvance] [bit] NOT NULL,
	[IsRecoveryContract] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[InterimInterestReceivableCodeId] [bigint] NULL,
	[LoanPrincipalReceivableCodeId] [bigint] NULL,
	[LoanInterestReceivableCodeId] [bigint] NULL,
	[LoanBookingGLTemplateId] [bigint] NULL,
	[LoanIncomeRecognitionGLTemplateId] [bigint] NULL,
	[InterimIncomeRecognitionGLTemplateId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[ContractOriginationId] [bigint] NOT NULL,
	[InstrumentTypeId] [bigint] NULL,
	[ReferralBankerId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[MasterAgreementId] [bigint] NULL,
	[AgreementTypeDetailId] [bigint] NULL,
	[IsNewMasterAgreement] [bit] NOT NULL,
	[CustomerTerm] [int] NULL,
	[PrepaymentPenaltyTemplateId] [bigint] NULL,
	[CreateInvoiceForAdvanceRental] [bit] NOT NULL,
	[SFDCUniqueId] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BillInterimAsOf] [nvarchar](35) COLLATE Latin1_General_CI_AS NULL,
	[CostCenterId] [bigint] NULL,
	[CanLockPayments] [bit] NOT NULL,
	[IsFederalIncomeTaxExempt] [bit] NOT NULL,
	[BranchId] [bigint] NULL,
	[IsBillInAlternateCurrency] [bit] NOT NULL,
	[IsRevolvingLoan] [bit] NOT NULL,
	[MinimumDueAmountComputation] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaymentAmount_Amount] [decimal](16, 2) NULL,
	[PaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Rate] [decimal](5, 2) NULL,
	[ExtendTerm] [bit] NOT NULL,
	[IsBlendedToBeRecomputed] [bit] NOT NULL,
	[EffectiveAnnualRate] [decimal](28, 18) NOT NULL,
	[PaymentDueForDSL] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_AgreementTypeDetail] FOREIGN KEY([AgreementTypeDetailId])
REFERENCES [dbo].[AgreementTypeDetails] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_AgreementTypeDetail]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_Branch]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_Contract]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_ContractOrigination] FOREIGN KEY([ContractOriginationId])
REFERENCES [dbo].[ContractOriginations] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_ContractOrigination]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_CostCenter]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_Customer]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_GLJournal]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_InstrumentType]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_InterimIncomeRecognitionGLTemplate] FOREIGN KEY([InterimIncomeRecognitionGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_InterimIncomeRecognitionGLTemplate]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_InterimInterestReceivableCode] FOREIGN KEY([InterimInterestReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_InterimInterestReceivableCode]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_LegalEntity]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_LineofBusiness]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanBookingGLTemplate] FOREIGN KEY([LoanBookingGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_LoanBookingGLTemplate]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanIncomeRecognitionGLTemplate] FOREIGN KEY([LoanIncomeRecognitionGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_LoanIncomeRecognitionGLTemplate]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanInterestReceivableCode] FOREIGN KEY([LoanInterestReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_LoanInterestReceivableCode]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanPrincipalReceivableCode] FOREIGN KEY([LoanPrincipalReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_LoanPrincipalReceivableCode]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_MasterAgreement] FOREIGN KEY([MasterAgreementId])
REFERENCES [dbo].[MasterAgreements] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_MasterAgreement]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_PrepaymentPenaltyTemplate] FOREIGN KEY([PrepaymentPenaltyTemplateId])
REFERENCES [dbo].[LoanPrepaymentPenaltyTemplates] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_PrepaymentPenaltyTemplate]
GO
ALTER TABLE [dbo].[LoanFinances]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_ReferralBanker] FOREIGN KEY([ReferralBankerId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[LoanFinances] CHECK CONSTRAINT [ELoanFinance_ReferralBanker]
GO
