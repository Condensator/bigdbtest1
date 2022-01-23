CREATE TYPE [dbo].[Customer] AS TABLE(
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
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
	[IsPostACHNotification] [bit] NOT NULL,
	[PostACHNotificationEmailTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsReturnACHNotification] [bit] NOT NULL,
	[ReturnACHNotificationEmailTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[SameDayCreditApprovals_Amount] [decimal](24, 2) NULL,
	[SameDayCreditApprovals_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ReplacementAmount_Amount] [decimal](24, 2) NULL,
	[ReplacementAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PricingIndicator] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[BaselRetail] [bit] NOT NULL,
	[ClabeNumber] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[IsBuyer] [bit] NOT NULL,
	[IsCustomerPortalAccessBlock] [bit] NOT NULL,
	[IsPEP] [bit] NOT NULL,
	[IsEPSMaster] [bit] NOT NULL,
	[IsHNW] [bit] NOT NULL,
	[AlsoKnownAs] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SalesForceCustomerName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CompanyURL] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[LegalNameValidationDate] [date] NULL,
	[PartyType] [nvarchar](42) COLLATE Latin1_General_CI_AS NULL,
	[IsMaterialAndRelevantPEP] [bit] NOT NULL,
	[IsMaterialAndRelevantAdverseMedia] [bit] NOT NULL,
	[CustomerRiskRating] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[CustomerRiskRatingScore] [decimal](16, 2) NOT NULL,
	[CustomerRiskRatingDates] [date] NULL,
	[PercentageOfGovernmentOwnership] [decimal](5, 2) NULL,
	[AnnualCreditReviewDate] [date] NULL,
	[ExtensionDate] [date] NULL,
	[NextReviewDate] [date] NULL,
	[PrimaryBusinessLevel1] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[TypeLevel2] [nvarchar](27) COLLATE Latin1_General_CI_AS NULL,
	[FacilitiesLevel4] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[OtherMiscLevel5] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[ManagementLevel6] [nvarchar](27) COLLATE Latin1_General_CI_AS NULL,
	[OwnershipLevel7] [nvarchar](28) COLLATE Latin1_General_CI_AS NULL,
	[IncomeTaxStatus] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[SFDCId] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Prospect] [bit] NOT NULL,
	[Priority] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[IsLimitedDisclosureParty] [bit] NOT NULL,
	[IsManualReviewRequired] [bit] NOT NULL,
	[IsFinancialDocumentRequired] [bit] NOT NULL,
	[IsBureauReportingExempt] [bit] NOT NULL,
	[FinancialDate] [date] NULL,
	[FinancialExpectedDate] [date] NULL,
	[CreditReviewFrequency] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[CreditScore] [decimal](16, 2) NOT NULL,
	[IsNonAccrualExempt] [bit] NOT NULL,
	[ConsentDate] [date] NULL,
	[IsRelatedToLessor] [bit] NOT NULL,
	[CreditDataReceivedDate] [date] NULL,
	[FiscalYearEndMonth] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[IsWithholdingTaxApplicable] [bit] NOT NULL,
	[IsRelatedtoPEP] [bit] NULL,
	[ParentPartyName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ParentPartyEIK] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsNotificationviaPhone] [bit] NULL,
	[IsNotificationviaSMS] [bit] NULL,
	[IsNotificationviaEMail] [bit] NULL,
	[LastLoanReviewById] [bigint] NULL,
	[BusinessTypeId] [bigint] NULL,
	[ReceiptHierarchyTemplateId] [bigint] NULL,
	[CustomerClassId] [bigint] NULL,
	[LateFeeTemplateId] [bigint] NULL,
	[BondRatingId] [bigint] NULL,
	[MedicalSpecialityId] [bigint] NULL,
	[CollectionStatusId] [bigint] NULL,
	[DebtorAttorneyId] [bigint] NULL,
	[ReceiverAttorneyId] [bigint] NULL,
	[AttorneyId] [bigint] NULL,
	[LegalStatusId] [bigint] NULL,
	[ApprovedExchangeId] [bigint] NULL,
	[ApprovedRegulatorId] [bigint] NULL,
	[BusinessTypeNAICSCodeId] [bigint] NULL,
	[BusinessTypesSICsCodeId] [bigint] NULL,
	[JurisdictionOfSovereignId] [bigint] NULL,
	[PreACHNotificationEmailTemplateId] [bigint] NULL,
	[PostACHNotificationEmailTemplateId] [bigint] NULL,
	[ReturnACHNotificationEmailTemplateId] [bigint] NULL,
	[BusinessBureauId] [bigint] NULL,
	[CustomerCreditBureauId] [bigint] NULL,
	[AlternateCreditBureauId] [bigint] NULL,
	[LegalFormationTypeConfigId] [bigint] NULL,
	[TaxExemptRuleId] [bigint] NOT NULL,
	[CIPDocumentSourceNameId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO