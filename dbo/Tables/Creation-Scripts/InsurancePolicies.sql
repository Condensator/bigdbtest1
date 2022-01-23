SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InsurancePolicies](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PolicyNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LossPayee] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsSelfInsured] [bit] NOT NULL,
	[IsApplicableToAllStates] [bit] NOT NULL,
	[IsCertificateReceived] [bit] NOT NULL,
	[CertificateReceivedDate] [date] NULL,
	[EffectiveDate] [date] NULL,
	[ExpirationDate] [date] NULL,
	[VerifiedDate] [date] NULL,
	[LastModifiedBy] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[LastModifiedDate] [date] NULL,
	[Type] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[IsSaved] [bit] NOT NULL,
	[IsEditMode] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[InsuranceCompanyId] [bigint] NULL,
	[InsuranceAgencyId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[StateId] [bigint] NULL,
	[VerifiedById] [bigint] NULL,
	[ContactPersonId] [bigint] NULL,
	[InsuranceAgentId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AdditionalInsured] [nvarchar](41) COLLATE Latin1_General_CI_AS NULL,
	[UniqueIdentificationNumber] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InsurancePolicies]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicy_ContactPerson] FOREIGN KEY([ContactPersonId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[InsurancePolicies] CHECK CONSTRAINT [EInsurancePolicy_ContactPerson]
GO
ALTER TABLE [dbo].[InsurancePolicies]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicy_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[InsurancePolicies] CHECK CONSTRAINT [EInsurancePolicy_Currency]
GO
ALTER TABLE [dbo].[InsurancePolicies]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicy_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[InsurancePolicies] CHECK CONSTRAINT [EInsurancePolicy_Customer]
GO
ALTER TABLE [dbo].[InsurancePolicies]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicy_InsuranceAgency] FOREIGN KEY([InsuranceAgencyId])
REFERENCES [dbo].[InsuranceAgencies] ([Id])
GO
ALTER TABLE [dbo].[InsurancePolicies] CHECK CONSTRAINT [EInsurancePolicy_InsuranceAgency]
GO
ALTER TABLE [dbo].[InsurancePolicies]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicy_InsuranceAgent] FOREIGN KEY([InsuranceAgentId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[InsurancePolicies] CHECK CONSTRAINT [EInsurancePolicy_InsuranceAgent]
GO
ALTER TABLE [dbo].[InsurancePolicies]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicy_InsuranceCompany] FOREIGN KEY([InsuranceCompanyId])
REFERENCES [dbo].[InsuranceCompanies] ([Id])
GO
ALTER TABLE [dbo].[InsurancePolicies] CHECK CONSTRAINT [EInsurancePolicy_InsuranceCompany]
GO
ALTER TABLE [dbo].[InsurancePolicies]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicy_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[InsurancePolicies] CHECK CONSTRAINT [EInsurancePolicy_LegalEntity]
GO
ALTER TABLE [dbo].[InsurancePolicies]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicy_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[InsurancePolicies] CHECK CONSTRAINT [EInsurancePolicy_State]
GO
ALTER TABLE [dbo].[InsurancePolicies]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicy_VerifiedBy] FOREIGN KEY([VerifiedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[InsurancePolicies] CHECK CONSTRAINT [EInsurancePolicy_VerifiedBy]
GO
