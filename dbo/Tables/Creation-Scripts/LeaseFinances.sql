SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseFinances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BookingStatus] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApprovalStatus] [nvarchar](25) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsCurrent] [bit] NOT NULL,
	[IsSalesTaxExempt] [bit] NOT NULL,
	[PropertyTaxResponsibility] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsPaymentScheduleGenerated] [bit] NOT NULL,
	[PaymentScheduleParametersChanged] [bit] NOT NULL,
	[IsPricedPerformed] [bit] NOT NULL,
	[PricingParametersChanged] [bit] NOT NULL,
	[ManagementYieldParametersChanged] [bit] NOT NULL,
	[SendToGAIC] [bit] NOT NULL,
	[GAICStatus] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[GAICRejectionReason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[HoldingStatus] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[HoldingStatusComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[PurchaseOrderNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AcquisitionId] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[InterimRentAdjustmentEffectiveDate] [date] NULL,
	[InterimRentUpdateHasBeenRun] [bit] NOT NULL,
	[InterimInterestAdjustmentEffectiveDate] [date] NULL,
	[InterimInterestUpdateHasBeenRun] [bit] NOT NULL,
	[LeaseStipLossDetailDocument_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[LeaseStipLossDetailDocument_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[LeaseStipLossDetailDocument_Content] [varbinary](82) NULL,
	[ClassificationTestParametersChanged] [bit] NOT NULL,
	[IsAMReviewCompleted] [bit] NOT NULL,
	[IsAMReviewRequired] [bit] NOT NULL,
	[IsFundingApproved] [bit] NOT NULL,
	[IsAccountingApproved] [bit] NOT NULL,
	[FloatRateUpdateRunDate] [date] NULL,
	[BankQualified] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[IsHostedSolution] [bit] NOT NULL,
	[IsRetrievedFromSalesTaxParametersChanged] [bit] NOT NULL,
	[IsRePricingParametersChanged] [bit] NOT NULL,
	[IsRetrievedFromSalesTax] [bit] NOT NULL,
	[CustomerClass] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsRepricedForSalesTax] [bit] NOT NULL,
	[IsFutureFunding] [bit] NOT NULL,
	[IsSalesTaxReviewRequired] [bit] NOT NULL,
	[IsSalesTaxReviewCompleted] [bit] NOT NULL,
	[IsSalesLeaseBackReviewCompleted] [bit] NOT NULL,
	[IsSalesTaxExemption] [bit] NOT NULL,
	[IsConduit] [bit] NOT NULL,
	[IsRecoveryContract] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[ContractOriginationId] [bigint] NOT NULL,
	[TaxProductTypeId] [bigint] NULL,
	[ThirdPartyResidualGuarantorId] [bigint] NULL,
	[ThirdPartyResidualGuarantorBillToId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[ReferralBankerId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsTaxReserve] [bit] NOT NULL,
	[Is467Lease] [bit] NOT NULL,
	[TimbreNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MasterAgreementId] [bigint] NULL,
	[AgreementTypeDetailId] [bigint] NULL,
	[IsNewMasterAgreement] [bit] NOT NULL,
	[SFDCUniqueId] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CostCenterId] [bigint] NULL,
	[TaxExemptRuleId] [bigint] NOT NULL,
	[IsFederalIncomeTaxExempt] [bit] NOT NULL,
	[IsNotQuotable] [bit] NOT NULL,
	[BranchId] [bigint] NULL,
	[IsBillInAlternateCurrency] [bit] NOT NULL,
	[RestructureOnFloatRateRunTillDate] [date] NULL,
	[VendorPayableCodeId] [bigint] NULL,
	[VendorWithholdingTaxRate] [decimal](5, 2) NULL,
	[IsOTPDepreciationParameterChanged] [bit] NOT NULL,
	[PayOffTemplateId] [bigint] NULL,
	[PreparedBy] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsSubleasing] [bit] NOT NULL,
	[IsFinancialRiskInsurance] [bit] NOT NULL,
	[IsVat] [bit] NOT NULL,
	[QuoteLeaseTypeId] [bigint] NOT NULL,
	[IsLetterOfConsentForPledge] [bit] NULL,
	[CreditAppId] [bigint] NULL,
	[InitialCostInvoiceJobId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_AgreementTypeDetail] FOREIGN KEY([AgreementTypeDetailId])
REFERENCES [dbo].[AgreementTypeDetails] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_AgreementTypeDetail]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_Branch]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_Contract]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_ContractOrigination] FOREIGN KEY([ContractOriginationId])
REFERENCES [dbo].[ContractOriginations] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_ContractOrigination]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_CostCenter]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_CreditApp] FOREIGN KEY([CreditAppId])
REFERENCES [dbo].[Opportunities] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_CreditApp]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_Customer]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_InitialCostInvoiceJob] FOREIGN KEY([InitialCostInvoiceJobId])
REFERENCES [dbo].[Jobs] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_InitialCostInvoiceJob]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_InstrumentType]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_LegalEntity]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_LineofBusiness]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_MasterAgreement] FOREIGN KEY([MasterAgreementId])
REFERENCES [dbo].[MasterAgreements] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_MasterAgreement]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_PayOffTemplate] FOREIGN KEY([PayOffTemplateId])
REFERENCES [dbo].[PayOffTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_PayOffTemplate]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_QuoteLeaseType] FOREIGN KEY([QuoteLeaseTypeId])
REFERENCES [dbo].[QuoteLeaseTypes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_QuoteLeaseType]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_ReferralBanker] FOREIGN KEY([ReferralBankerId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_ReferralBanker]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_TaxExemptRule] FOREIGN KEY([TaxExemptRuleId])
REFERENCES [dbo].[TaxExemptRules] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_TaxExemptRule]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_TaxProductType] FOREIGN KEY([TaxProductTypeId])
REFERENCES [dbo].[TaxProductTypes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_TaxProductType]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_ThirdPartyResidualGuarantor] FOREIGN KEY([ThirdPartyResidualGuarantorId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_ThirdPartyResidualGuarantor]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_ThirdPartyResidualGuarantorBillTo] FOREIGN KEY([ThirdPartyResidualGuarantorBillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_ThirdPartyResidualGuarantorBillTo]
GO
ALTER TABLE [dbo].[LeaseFinances]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_VendorPayableCode] FOREIGN KEY([VendorPayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinances] CHECK CONSTRAINT [ELeaseFinance_VendorPayableCode]
GO
