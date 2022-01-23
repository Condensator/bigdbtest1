SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OpportunityCustomers](
	[Id] [bigint] NOT NULL,
	[IsCorporate] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsSoleProprietor] [bit] NOT NULL,
	[FirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CompanyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CustomerName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[UniqueIdentificationNumber_CT] [varbinary](32) NULL,
	[LastFourDigitUniqueIdentificationNumber] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[CreationDate] [date] NOT NULL,
	[LegalNameValidationDate] [date] NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[CIPDocumentSourceForName] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[PartyType] [nvarchar](42) COLLATE Latin1_General_CI_AS NULL,
	[IncomeTaxStatus] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[DateOfBirth] [date] NULL,
	[PercentageOfGovernmentOwnership] [decimal](5, 2) NULL,
	[IsBillingAddressSameAsMain] [bit] NOT NULL,
	[AddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Division] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[HomeAddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[HomeAddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[HomeCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[HomeDivision] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[HomePostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[LegalFormationTypeConfigId] [bigint] NULL,
	[StateOfIncorporationId] [bigint] NULL,
	[BusinessTypeId] [bigint] NOT NULL,
	[CustomerId] [bigint] NULL,
	[BusinessTypeNAICSCodeId] [bigint] NULL,
	[ApprovedExchangeId] [bigint] NULL,
	[ApprovedRegulatorId] [bigint] NULL,
	[JurisdictionOfSovereignId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[HomeStateId] [bigint] NULL,
	[CIPDocumentSourceNameId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsVATRegistration] [bit] NULL,
	[EIKNumber_CT] [varbinary](64) NULL,
	[WayOfRepresentation] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Representative1] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Representative2] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Representative3] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[VATRegistration] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[NationalIdCardNumber_CT] [varbinary](64) NULL,
	[Settlement] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[HomeSettlement] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[HomeAddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Neighborhood] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[HomeNeighborhood] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[HomeSubdivisionOrMunicipality] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[SubdivisionOrMunicipality] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[IssuedIn] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[DateofIssueID] [date] NULL,
	[Gender] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[MiddleName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BusinessTypesSICsCodeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[OpportunityCustomers]  WITH CHECK ADD  CONSTRAINT [EOpportunity_OpportunityCustomer] FOREIGN KEY([Id])
REFERENCES [dbo].[Opportunities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[OpportunityCustomers] CHECK CONSTRAINT [EOpportunity_OpportunityCustomer]
GO
ALTER TABLE [dbo].[OpportunityCustomers]  WITH CHECK ADD  CONSTRAINT [EOpportunityCustomer_ApprovedExchange] FOREIGN KEY([ApprovedExchangeId])
REFERENCES [dbo].[CustomerApprovedExchangesConfigs] ([Id])
GO
ALTER TABLE [dbo].[OpportunityCustomers] CHECK CONSTRAINT [EOpportunityCustomer_ApprovedExchange]
GO
ALTER TABLE [dbo].[OpportunityCustomers]  WITH CHECK ADD  CONSTRAINT [EOpportunityCustomer_ApprovedRegulator] FOREIGN KEY([ApprovedRegulatorId])
REFERENCES [dbo].[CustomerApprovedRegulatorsConfigs] ([Id])
GO
ALTER TABLE [dbo].[OpportunityCustomers] CHECK CONSTRAINT [EOpportunityCustomer_ApprovedRegulator]
GO
ALTER TABLE [dbo].[OpportunityCustomers]  WITH CHECK ADD  CONSTRAINT [EOpportunityCustomer_BusinessType] FOREIGN KEY([BusinessTypeId])
REFERENCES [dbo].[BusinessTypes] ([Id])
GO
ALTER TABLE [dbo].[OpportunityCustomers] CHECK CONSTRAINT [EOpportunityCustomer_BusinessType]
GO
ALTER TABLE [dbo].[OpportunityCustomers]  WITH CHECK ADD  CONSTRAINT [EOpportunityCustomer_BusinessTypeNAICSCode] FOREIGN KEY([BusinessTypeNAICSCodeId])
REFERENCES [dbo].[BusinessTypeNAICSCodes] ([Id])
GO
ALTER TABLE [dbo].[OpportunityCustomers] CHECK CONSTRAINT [EOpportunityCustomer_BusinessTypeNAICSCode]
GO
ALTER TABLE [dbo].[OpportunityCustomers]  WITH CHECK ADD  CONSTRAINT [EOpportunityCustomer_BusinessTypesSICsCode] FOREIGN KEY([BusinessTypesSICsCodeId])
REFERENCES [dbo].[BusinessTypesSICsCodes] ([Id])
GO
ALTER TABLE [dbo].[OpportunityCustomers] CHECK CONSTRAINT [EOpportunityCustomer_BusinessTypesSICsCode]
GO
ALTER TABLE [dbo].[OpportunityCustomers]  WITH CHECK ADD  CONSTRAINT [EOpportunityCustomer_CIPDocumentSourceName] FOREIGN KEY([CIPDocumentSourceNameId])
REFERENCES [dbo].[CIPDocumentSourceConfigs] ([Id])
GO
ALTER TABLE [dbo].[OpportunityCustomers] CHECK CONSTRAINT [EOpportunityCustomer_CIPDocumentSourceName]
GO
ALTER TABLE [dbo].[OpportunityCustomers]  WITH CHECK ADD  CONSTRAINT [EOpportunityCustomer_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[OpportunityCustomers] CHECK CONSTRAINT [EOpportunityCustomer_Customer]
GO
ALTER TABLE [dbo].[OpportunityCustomers]  WITH CHECK ADD  CONSTRAINT [EOpportunityCustomer_HomeState] FOREIGN KEY([HomeStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[OpportunityCustomers] CHECK CONSTRAINT [EOpportunityCustomer_HomeState]
GO
ALTER TABLE [dbo].[OpportunityCustomers]  WITH CHECK ADD  CONSTRAINT [EOpportunityCustomer_JurisdictionOfSovereign] FOREIGN KEY([JurisdictionOfSovereignId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[OpportunityCustomers] CHECK CONSTRAINT [EOpportunityCustomer_JurisdictionOfSovereign]
GO
ALTER TABLE [dbo].[OpportunityCustomers]  WITH CHECK ADD  CONSTRAINT [EOpportunityCustomer_LegalFormationTypeConfig] FOREIGN KEY([LegalFormationTypeConfigId])
REFERENCES [dbo].[LegalFormationTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[OpportunityCustomers] CHECK CONSTRAINT [EOpportunityCustomer_LegalFormationTypeConfig]
GO
ALTER TABLE [dbo].[OpportunityCustomers]  WITH CHECK ADD  CONSTRAINT [EOpportunityCustomer_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[OpportunityCustomers] CHECK CONSTRAINT [EOpportunityCustomer_State]
GO
ALTER TABLE [dbo].[OpportunityCustomers]  WITH CHECK ADD  CONSTRAINT [EOpportunityCustomer_StateOfIncorporation] FOREIGN KEY([StateOfIncorporationId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[OpportunityCustomers] CHECK CONSTRAINT [EOpportunityCustomer_StateOfIncorporation]
GO
