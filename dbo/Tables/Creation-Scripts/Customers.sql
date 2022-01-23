SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Customers](
	[Id] [bigint] NOT NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActivationDate] [date] NULL,
	[InactivationDate] [date] NULL,
	[InactivationReason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsLienFilingRequired] [bit] NOT NULL,
	[OrganizationID] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[OwnershipPattern] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[OriginationSourceType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[CIPDocumentSourceForName] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[CIPDocumentSourceForAddress] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[CIPDocumentSourceForTaxIdOrSSN] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[IsNSFChargeEligible] [bit] NOT NULL,
	[InvoiceTransitDays] [int] NOT NULL,
	[InvoiceBillingCycle] [int] NOT NULL,
	[InvoiceGraceDays] [int] NOT NULL,
	[InvoiceLeadDays] [int] NOT NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceCommentBeginDate] [date] NULL,
	[InvoiceCommentEndDate] [date] NULL,
	[IsConsolidated] [bit] NOT NULL,
	[DeliverInvoiceViaMail] [bit] NOT NULL,
	[DeliverInvoiceViaEmail] [bit] NOT NULL,
	[InvoiceEmailTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceEmailCC] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceEmailBCC] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[RevenueAmount_Amount] [decimal](16, 2) NULL,
	[RevenueAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[BankLendingStrategy] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[EFLendingStrategy] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[LoanReviewDueDate] [date] NULL,
	[LoanReviewResponsibility] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[LoanReviewCompletedDate] [date] NULL,
	[LoanReviewCompletedBy] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[BankCreditExposureDirect_Amount] [decimal](16, 2) NOT NULL,
	[BankCreditExposureDirect_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BankCreditExposureIndirect_Amount] [decimal](16, 2) NOT NULL,
	[BankCreditExposureIndirect_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BankCreditExposureDate] [date] NULL,
	[ObligorRating] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[IsBankrupt] [bit] NOT NULL,
	[StockSymbol] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[BusinessStartDate] [date] NULL,
	[MonthsInBusiness] [int] NULL,
	[OwnerStartDate] [date] NULL,
	[MonthsAsOwner] [int] NULL,
	[BusinessBureauNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[LastPaynetExtractDate] [date] NULL,
	[NumberOfBeds] [int] NULL,
	[OccupancyRate] [decimal](16, 2) NULL,
	[LicenseDate] [date] NULL,
	[OwnershipType] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[DebtRatio] [decimal](5, 2) NULL,
	[IsSCRA] [bit] NOT NULL,
	[SCRAStartDate] [date] NULL,
	[SCRAEndDate] [date] NULL,
	[BenefitsAndProtection] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[IsPreACHNotification] [bit] NOT NULL,
	[PreACHNotificationEmailTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[SameDayCreditApprovals_Amount] [decimal](24, 2) NULL,
	[SameDayCreditApprovals_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ReplacementAmount_Amount] [decimal](24, 2) NULL,
	[ReplacementAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PricingIndicator] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[BaselRetail] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LastLoanReviewById] [bigint] NULL,
	[BusinessTypeId] [bigint] NULL,
	[ReceiptHierarchyTemplateId] [bigint] NULL,
	[CustomerClassId] [bigint] NULL,
	[LateFeeTemplateId] [bigint] NULL,
	[BondRatingId] [bigint] NULL,
	[CollectionStatusId] [bigint] NULL,
	[DebtorAttorneyId] [bigint] NULL,
	[ReceiverAttorneyId] [bigint] NULL,
	[AttorneyId] [bigint] NULL,
	[LegalStatusId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ClabeNumber] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[IsBuyer] [bit] NOT NULL,
	[IsCustomerPortalAccessBlock] [bit] NOT NULL,
	[IsPEP] [bit] NOT NULL,
	[IsHNW] [bit] NOT NULL,
	[AlsoKnownAs] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SalesForceCustomerName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LegalNameValidationDate] [date] NULL,
	[CompanyURL] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[PartyType] [nvarchar](42) COLLATE Latin1_General_CI_AS NULL,
	[IsMaterialAndRelevantPEP] [bit] NOT NULL,
	[IsMaterialAndRelevantAdverseMedia] [bit] NOT NULL,
	[CustomerRiskRating] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[CustomerRiskRatingScore] [decimal](16, 2) NOT NULL,
	[CustomerRiskRatingDates] [date] NULL,
	[PercentageOfGovernmentOwnership] [decimal](5, 2) NULL,
	[ApprovedExchangeId] [bigint] NULL,
	[ApprovedRegulatorId] [bigint] NULL,
	[IncomeTaxStatus] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[AnnualCreditReviewDate] [date] NULL,
	[ExtensionDate] [date] NULL,
	[PrimaryBusinessLevel1] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[TypeLevel2] [nvarchar](27) COLLATE Latin1_General_CI_AS NULL,
	[FacilitiesLevel4] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[OtherMiscLevel5] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[ManagementLevel6] [nvarchar](27) COLLATE Latin1_General_CI_AS NULL,
	[OwnershipLevel7] [nvarchar](28) COLLATE Latin1_General_CI_AS NULL,
	[IsEPSMaster] [bit] NOT NULL,
	[BusinessTypeNAICSCodeId] [bigint] NULL,
	[MedicalSpecialityId] [bigint] NULL,
	[JurisdictionOfSovereignId] [bigint] NULL,
	[SFDCId] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PreACHNotificationEmailTemplateId] [bigint] NULL,
	[BusinessBureauId] [bigint] NULL,
	[CustomerCreditBureauId] [bigint] NULL,
	[AlternateCreditBureauId] [bigint] NULL,
	[LegalFormationTypeConfigId] [bigint] NULL,
	[TaxExemptRuleId] [bigint] NOT NULL,
	[Prospect] [bit] NOT NULL,
	[Priority] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[IsLimitedDisclosureParty] [bit] NOT NULL,
	[NextReviewDate] [date] NULL,
	[IsManualReviewRequired] [bit] NOT NULL,
	[IsFinancialDocumentRequired] [bit] NOT NULL,
	[FinancialDate] [date] NULL,
	[FinancialExpectedDate] [date] NULL,
	[CreditReviewFrequency] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[CreditScore] [decimal](16, 2) NOT NULL,
	[IsBureauReportingExempt] [bit] NOT NULL,
	[IsNonAccrualExempt] [bit] NOT NULL,
	[ConsentDate] [date] NULL,
	[CIPDocumentSourceNameId] [bigint] NULL,
	[IsRelatedToLessor] [bit] NOT NULL,
	[CreditDataReceivedDate] [date] NULL,
	[FiscalYearEndMonth] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[IsWithholdingTaxApplicable] [bit] NOT NULL,
	[IsPostACHNotification] [bit] NOT NULL,
	[PostACHNotificationEmailTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[PostACHNotificationEmailTemplateId] [bigint] NULL,
	[IsReturnACHNotification] [bit] NOT NULL,
	[ReturnACHNotificationEmailTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[ReturnACHNotificationEmailTemplateId] [bigint] NULL,
	[IsRelatedtoPEP] [bit] NULL,
	[ParentPartyName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ParentPartyEIK] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsNotificationviaPhone] [bit] NULL,
	[IsNotificationviaSMS] [bit] NULL,
	[IsNotificationviaEMail] [bit] NULL,
	[BusinessTypesSICsCodeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_AlternateCreditBureau] FOREIGN KEY([AlternateCreditBureauId])
REFERENCES [dbo].[CreditBureauConfigs] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_AlternateCreditBureau]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_ApprovedExchange] FOREIGN KEY([ApprovedExchangeId])
REFERENCES [dbo].[CustomerApprovedExchangesConfigs] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_ApprovedExchange]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_ApprovedRegulator] FOREIGN KEY([ApprovedRegulatorId])
REFERENCES [dbo].[CustomerApprovedRegulatorsConfigs] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_ApprovedRegulator]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_Attorney] FOREIGN KEY([AttorneyId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_Attorney]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_BondRating] FOREIGN KEY([BondRatingId])
REFERENCES [dbo].[BondRatings] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_BondRating]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_BusinessBureau] FOREIGN KEY([BusinessBureauId])
REFERENCES [dbo].[CreditBureauConfigs] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_BusinessBureau]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_BusinessType] FOREIGN KEY([BusinessTypeId])
REFERENCES [dbo].[BusinessTypes] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_BusinessType]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_BusinessTypeNAICSCode] FOREIGN KEY([BusinessTypeNAICSCodeId])
REFERENCES [dbo].[BusinessTypeNAICSCodes] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_BusinessTypeNAICSCode]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_BusinessTypesSICsCode] FOREIGN KEY([BusinessTypesSICsCodeId])
REFERENCES [dbo].[BusinessTypesSICsCodes] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_BusinessTypesSICsCode]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_CIPDocumentSourceName] FOREIGN KEY([CIPDocumentSourceNameId])
REFERENCES [dbo].[CIPDocumentSourceConfigs] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_CIPDocumentSourceName]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_CollectionStatus] FOREIGN KEY([CollectionStatusId])
REFERENCES [dbo].[CollectionStatus] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_CollectionStatus]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_CustomerClass] FOREIGN KEY([CustomerClassId])
REFERENCES [dbo].[CustomerClasses] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_CustomerClass]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_CustomerCreditBureau] FOREIGN KEY([CustomerCreditBureauId])
REFERENCES [dbo].[CreditBureauConfigs] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_CustomerCreditBureau]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_DebtorAttorney] FOREIGN KEY([DebtorAttorneyId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_DebtorAttorney]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_JurisdictionOfSovereign] FOREIGN KEY([JurisdictionOfSovereignId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_JurisdictionOfSovereign]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_LastLoanReviewBy] FOREIGN KEY([LastLoanReviewById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_LastLoanReviewBy]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_LateFeeTemplate] FOREIGN KEY([LateFeeTemplateId])
REFERENCES [dbo].[LateFeeTemplates] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_LateFeeTemplate]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_LegalFormationTypeConfig] FOREIGN KEY([LegalFormationTypeConfigId])
REFERENCES [dbo].[LegalFormationTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_LegalFormationTypeConfig]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_LegalStatus] FOREIGN KEY([LegalStatusId])
REFERENCES [dbo].[LegalStatusConfigs] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_LegalStatus]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_MedicalSpeciality] FOREIGN KEY([MedicalSpecialityId])
REFERENCES [dbo].[MedicalSpecialities] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_MedicalSpeciality]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_PostACHNotificationEmailTemplate] FOREIGN KEY([PostACHNotificationEmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_PostACHNotificationEmailTemplate]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_PreACHNotificationEmailTemplate] FOREIGN KEY([PreACHNotificationEmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_PreACHNotificationEmailTemplate]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_ReceiptHierarchyTemplate] FOREIGN KEY([ReceiptHierarchyTemplateId])
REFERENCES [dbo].[ReceiptHierarchyTemplates] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_ReceiptHierarchyTemplate]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_ReceiverAttorney] FOREIGN KEY([ReceiverAttorneyId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_ReceiverAttorney]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_ReturnACHNotificationEmailTemplate] FOREIGN KEY([ReturnACHNotificationEmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_ReturnACHNotificationEmailTemplate]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [ECustomer_TaxExemptRule] FOREIGN KEY([TaxExemptRuleId])
REFERENCES [dbo].[TaxExemptRules] ([Id])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [ECustomer_TaxExemptRule]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [EParty_Customer] FOREIGN KEY([Id])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [EParty_Customer]
GO
