SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Opportunities](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[Conduit] [bit] NOT NULL,
	[Confidential] [bit] NOT NULL,
	[BankQualified] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[CapitalStreamUniqueId] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ReplacementSchedule] [bit] NOT NULL,
	[ManagementSegment] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsAMReviewDone] [bit] NOT NULL,
	[IsOriginatedinLW] [bit] NOT NULL,
	[ReportStatus] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LineofBusinessId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[OriginationSourceTypeId] [bigint] NOT NULL,
	[OriginationSourceId] [bigint] NULL,
	[OriginationSourceUserId] [bigint] NULL,
	[AcquiredPortfolioId] [bigint] NULL,
	[ReferralBankerId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[SingleSignOnIdentification] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ShellCustomerContactId] [bigint] NULL,
	[ShellCustomerDetailId] [bigint] NULL,
	[CostCenterId] [bigint] NOT NULL,
	[ShellCustomerAddressId] [bigint] NULL,
	[IsFederalIncomeTaxExempt] [bit] NOT NULL,
	[OpportunityLostReason] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[WithdrawnReasonCode] [nvarchar](26) COLLATE Latin1_General_CI_AS NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[CountryId] [bigint] NULL,
	[IsCustomerCreationRequired] [bit] NOT NULL,
	[BranchId] [bigint] NULL,
	[IsLeaseCreated] [bit] NOT NULL,
	[OriginationChannelId] [bigint] NOT NULL,
	[IsAutomaticScoringSkipped] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_AcquiredPortfolio] FOREIGN KEY([AcquiredPortfolioId])
REFERENCES [dbo].[AcquiredPortfolios] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_AcquiredPortfolio]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_Branch]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_BusinessUnit]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_CostCenter]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_Country]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_Currency]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_Customer]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_LegalEntity]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_LineofBusiness]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_OriginationChannel] FOREIGN KEY([OriginationChannelId])
REFERENCES [dbo].[OriginationSourceTypes] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_OriginationChannel]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_OriginationSource] FOREIGN KEY([OriginationSourceId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_OriginationSource]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_OriginationSourceType] FOREIGN KEY([OriginationSourceTypeId])
REFERENCES [dbo].[OriginationSourceTypes] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_OriginationSourceType]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_OriginationSourceUser] FOREIGN KEY([OriginationSourceUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_OriginationSourceUser]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_ReferralBanker] FOREIGN KEY([ReferralBankerId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_ReferralBanker]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_ShellCustomerAddress] FOREIGN KEY([ShellCustomerAddressId])
REFERENCES [dbo].[ShellCustomerAddresses] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_ShellCustomerAddress]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_ShellCustomerContact] FOREIGN KEY([ShellCustomerContactId])
REFERENCES [dbo].[ShellCustomerContacts] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_ShellCustomerContact]
GO
ALTER TABLE [dbo].[Opportunities]  WITH CHECK ADD  CONSTRAINT [EOpportunity_ShellCustomerDetail] FOREIGN KEY([ShellCustomerDetailId])
REFERENCES [dbo].[ShellCustomerDetails] ([Id])
GO
ALTER TABLE [dbo].[Opportunities] CHECK CONSTRAINT [EOpportunity_ShellCustomerDetail]
GO
