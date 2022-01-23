SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditProfileCustomers](
	[Id] [bigint] NOT NULL,
	[IsCorporate] [bit] NOT NULL,
	[IsSoleProprietor] [bit] NOT NULL,
	[FirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CompanyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CustomerName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreationDate] [date] NOT NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[CIPDocumentSourceForName] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[PartyType] [nvarchar](42) COLLATE Latin1_General_CI_AS NOT NULL,
	[IncomeTaxStatus] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[DateOfBirth] [date] NULL,
	[PercentageOfGovernmentOwnership] [decimal](5, 2) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalFormationTypeConfigId] [bigint] NOT NULL,
	[StateOfIncorporationId] [bigint] NOT NULL,
	[BusinessTypeId] [bigint] NOT NULL,
	[CustomerId] [bigint] NULL,
	[BusinessTypeNAICSCodeId] [bigint] NULL,
	[ApprovedExchangeId] [bigint] NULL,
	[ApprovedRegulatorId] [bigint] NULL,
	[JurisdictionOfSovereignId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Division] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[StateId] [bigint] NULL,
	[LegalNameValidationDate] [date] NOT NULL,
	[IsBillingAddressSameAsMain] [bit] NOT NULL,
	[HomeAddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[HomeAddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[HomeCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[HomeDivision] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[HomePostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[HomeStateId] [bigint] NULL,
	[LastFourDigitUniqueIdentificationNumber] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[UniqueIdentificationNumber_CT] [varbinary](32) NULL,
	[ConsentDate] [date] NULL,
	[CIPDocumentSourceNameId] [bigint] NULL,
	[BusinessTypesSICsCodeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditProfileCustomers]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditProfileCustomer] FOREIGN KEY([Id])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditProfileCustomers] CHECK CONSTRAINT [ECreditProfile_CreditProfileCustomer]
GO
ALTER TABLE [dbo].[CreditProfileCustomers]  WITH CHECK ADD  CONSTRAINT [ECreditProfileCustomer_ApprovedExchange] FOREIGN KEY([ApprovedExchangeId])
REFERENCES [dbo].[CustomerApprovedExchangesConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileCustomers] CHECK CONSTRAINT [ECreditProfileCustomer_ApprovedExchange]
GO
ALTER TABLE [dbo].[CreditProfileCustomers]  WITH CHECK ADD  CONSTRAINT [ECreditProfileCustomer_ApprovedRegulator] FOREIGN KEY([ApprovedRegulatorId])
REFERENCES [dbo].[CustomerApprovedRegulatorsConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileCustomers] CHECK CONSTRAINT [ECreditProfileCustomer_ApprovedRegulator]
GO
ALTER TABLE [dbo].[CreditProfileCustomers]  WITH CHECK ADD  CONSTRAINT [ECreditProfileCustomer_BusinessType] FOREIGN KEY([BusinessTypeId])
REFERENCES [dbo].[BusinessTypes] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileCustomers] CHECK CONSTRAINT [ECreditProfileCustomer_BusinessType]
GO
ALTER TABLE [dbo].[CreditProfileCustomers]  WITH CHECK ADD  CONSTRAINT [ECreditProfileCustomer_BusinessTypeNAICSCode] FOREIGN KEY([BusinessTypeNAICSCodeId])
REFERENCES [dbo].[BusinessTypeNAICSCodes] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileCustomers] CHECK CONSTRAINT [ECreditProfileCustomer_BusinessTypeNAICSCode]
GO
ALTER TABLE [dbo].[CreditProfileCustomers]  WITH CHECK ADD  CONSTRAINT [ECreditProfileCustomer_BusinessTypesSICsCode] FOREIGN KEY([BusinessTypesSICsCodeId])
REFERENCES [dbo].[BusinessTypesSICsCodes] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileCustomers] CHECK CONSTRAINT [ECreditProfileCustomer_BusinessTypesSICsCode]
GO
ALTER TABLE [dbo].[CreditProfileCustomers]  WITH CHECK ADD  CONSTRAINT [ECreditProfileCustomer_CIPDocumentSourceName] FOREIGN KEY([CIPDocumentSourceNameId])
REFERENCES [dbo].[CIPDocumentSourceConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileCustomers] CHECK CONSTRAINT [ECreditProfileCustomer_CIPDocumentSourceName]
GO
ALTER TABLE [dbo].[CreditProfileCustomers]  WITH CHECK ADD  CONSTRAINT [ECreditProfileCustomer_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileCustomers] CHECK CONSTRAINT [ECreditProfileCustomer_Customer]
GO
ALTER TABLE [dbo].[CreditProfileCustomers]  WITH CHECK ADD  CONSTRAINT [ECreditProfileCustomer_HomeState] FOREIGN KEY([HomeStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileCustomers] CHECK CONSTRAINT [ECreditProfileCustomer_HomeState]
GO
ALTER TABLE [dbo].[CreditProfileCustomers]  WITH CHECK ADD  CONSTRAINT [ECreditProfileCustomer_JurisdictionOfSovereign] FOREIGN KEY([JurisdictionOfSovereignId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileCustomers] CHECK CONSTRAINT [ECreditProfileCustomer_JurisdictionOfSovereign]
GO
ALTER TABLE [dbo].[CreditProfileCustomers]  WITH CHECK ADD  CONSTRAINT [ECreditProfileCustomer_LegalFormationTypeConfig] FOREIGN KEY([LegalFormationTypeConfigId])
REFERENCES [dbo].[LegalFormationTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileCustomers] CHECK CONSTRAINT [ECreditProfileCustomer_LegalFormationTypeConfig]
GO
ALTER TABLE [dbo].[CreditProfileCustomers]  WITH CHECK ADD  CONSTRAINT [ECreditProfileCustomer_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileCustomers] CHECK CONSTRAINT [ECreditProfileCustomer_State]
GO
ALTER TABLE [dbo].[CreditProfileCustomers]  WITH CHECK ADD  CONSTRAINT [ECreditProfileCustomer_StateOfIncorporation] FOREIGN KEY([StateOfIncorporationId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileCustomers] CHECK CONSTRAINT [ECreditProfileCustomer_StateOfIncorporation]
GO
