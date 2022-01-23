SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditProfiles](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[RequestedAmount_Amount] [decimal](16, 2) NOT NULL,
	[RequestedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApprovedAmount_Amount] [decimal](16, 2) NULL,
	[ApprovedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[UsedAmount_Amount] [decimal](16, 2) NULL,
	[UsedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsSyndicated] [bit] NOT NULL,
	[IsRevolving] [bit] NOT NULL,
	[IsCommitted] [bit] NOT NULL,
	[Comment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](31) COLLATE Latin1_General_CI_AS NULL,
	[CreditCancelReasonCode] [nvarchar](26) COLLATE Latin1_General_CI_AS NULL,
	[RegBDeclinationCode] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[IsSNCCode] [bit] NOT NULL,
	[SNCRating] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[SNCRole] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[SNCAgent] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[SNCRatingDate] [date] NULL,
	[IsCostConfigUsed] [bit] NOT NULL,
	[IsPreApproval] [bit] NOT NULL,
	[IsConfidential] [bit] NOT NULL,
	[IsConduit] [bit] NOT NULL,
	[BankQualified] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[HoldingStatus] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[AcquisitionId] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[IsHostedsolution] [bit] NOT NULL,
	[CapitalStreamProductType] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[ReplacementSchedule] [bit] NOT NULL,
	[PeakExposure_Amount] [decimal](16, 2) NULL,
	[PeakExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ManagementSegment] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsCreditInLW] [bit] NOT NULL,
	[CreditAppVerified] [bit] NOT NULL,
	[IsPGChanged] [bit] NOT NULL,
	[CustomerLookUpStatus] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsCreditDataGatheringDone] [bit] NOT NULL,
	[IsOFACReviewDone] [bit] NOT NULL,
	[IsCustomerLookupComplete] [bit] NOT NULL,
	[IsAdditionalApprovalComplete] [bit] NOT NULL,
	[StatusDate] [date] NULL,
	[ReportStatus] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[OpportunityId] [bigint] NULL,
	[OriginationSourceTypeId] [bigint] NOT NULL,
	[OriginationSourceId] [bigint] NULL,
	[OriginationSourceUserId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[AcquiredPortfolioId] [bigint] NULL,
	[ReferralBankerId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustomerCreditScore] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[IsPreApproved] [bit] NOT NULL,
	[LineOfCreditId] [bigint] NULL,
	[SingleSignOnIdentification] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SFDCUniqueId] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ShellCustomerContactId] [bigint] NULL,
	[ShellCustomerDetailId] [bigint] NULL,
	[CostCenterId] [bigint] NOT NULL,
	[ShellCustomerAddressId] [bigint] NULL,
	[IsFutureFunding] [bit] NOT NULL,
	[ProductAndServiceTypeConfigId] [bigint] NULL,
	[DocumentMethod] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[IsCustomerCreationRequired] [bit] NOT NULL,
	[IsFederalIncomeTaxExempt] [bit] NOT NULL,
	[EquipmentVendorId] [bigint] NULL,
	[PreApprovalLOCId] [bigint] NULL,
	[ServicingRole] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[ProgramId] [bigint] NULL,
	[ProgramVendorOriginationSourceId] [bigint] NULL,
	[CountryId] [bigint] NULL,
	[ToleranceAmount_Amount] [decimal](16, 2) NOT NULL,
	[ToleranceAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_AcquiredPortfolio] FOREIGN KEY([AcquiredPortfolioId])
REFERENCES [dbo].[AcquiredPortfolios] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_AcquiredPortfolio]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_BusinessUnit]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_CostCenter]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_Country]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_Currency]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_Customer]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_EquipmentVendor] FOREIGN KEY([EquipmentVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_EquipmentVendor]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_LegalEntity]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_LineofBusiness]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_LineOfCredit] FOREIGN KEY([LineOfCreditId])
REFERENCES [dbo].[CreditProfiles] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_LineOfCredit]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_Opportunity] FOREIGN KEY([OpportunityId])
REFERENCES [dbo].[Opportunities] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_Opportunity]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_OriginationSource] FOREIGN KEY([OriginationSourceId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_OriginationSource]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_OriginationSourceType] FOREIGN KEY([OriginationSourceTypeId])
REFERENCES [dbo].[OriginationSourceTypes] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_OriginationSourceType]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_OriginationSourceUser] FOREIGN KEY([OriginationSourceUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_OriginationSourceUser]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_PreApprovalLOC] FOREIGN KEY([PreApprovalLOCId])
REFERENCES [dbo].[CreditProfiles] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_PreApprovalLOC]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_ProductAndServiceTypeConfig] FOREIGN KEY([ProductAndServiceTypeConfigId])
REFERENCES [dbo].[ProductAndServiceTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_ProductAndServiceTypeConfig]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_Program] FOREIGN KEY([ProgramId])
REFERENCES [dbo].[Programs] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_Program]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_ProgramVendorOriginationSource] FOREIGN KEY([ProgramVendorOriginationSourceId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_ProgramVendorOriginationSource]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_ReferralBanker] FOREIGN KEY([ReferralBankerId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_ReferralBanker]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_ShellCustomerAddress] FOREIGN KEY([ShellCustomerAddressId])
REFERENCES [dbo].[ShellCustomerAddresses] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_ShellCustomerAddress]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_ShellCustomerContact] FOREIGN KEY([ShellCustomerContactId])
REFERENCES [dbo].[ShellCustomerContacts] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_ShellCustomerContact]
GO
ALTER TABLE [dbo].[CreditProfiles]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_ShellCustomerDetail] FOREIGN KEY([ShellCustomerDetailId])
REFERENCES [dbo].[ShellCustomerDetails] ([Id])
GO
ALTER TABLE [dbo].[CreditProfiles] CHECK CONSTRAINT [ECreditProfile_ShellCustomerDetail]
GO
