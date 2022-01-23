SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Parties](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PartyNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsCorporate] [bit] NOT NULL,
	[FirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CompanyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[PartyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Alias] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DateOfBirth] [date] MASKED WITH (FUNCTION = 'default()') NULL,
	[DoingBusinessAs] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreationDate] [date] NOT NULL,
	[IncorporationDate] [date] NULL,
	[CurrentRole] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[IsSoleProprietor] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ParentPartyId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PartyEntityType] [nvarchar](39) COLLATE Latin1_General_CI_AS NULL,
	[MiddleName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[StateOfIncorporationId] [bigint] NULL,
	[IsIntercompany] [bit] NOT NULL,
	[LastFourDigitUniqueIdentificationNumber] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[UniqueIdentificationNumber_CT] [varbinary](48) NULL,
	[LanguageId] [bigint] NULL,
	[VATRegistrationNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[ExternalPartyNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Suffix] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsVATRegistration] [bit] NULL,
	[EIKNumber_CT] [varbinary](64) NULL,
	[WayOfRepresentation] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Representative1] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Representative2] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Representative3] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[VATRegistration] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[DateofIssueID] [date] NULL,
	[IssuedIn] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Gender] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[IsForeigner] [bit] NULL,
	[Ln4] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[PassportNo] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[DateofIssue] [date] NULL,
	[PassportCountry] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[PassportAddress] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsSpecialClient] [bit] NOT NULL,
	[EquityOwnerEGN1] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EquityOwnerEGN2] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EquityOwnerEGN3] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CustomerLegalStatusId] [bigint] NULL,
	[SectorId] [bigint] NULL,
	[ProfessionsId] [bigint] NULL,
	[NationalIdCardNumber_CT] [varbinary](64) NULL,
	[Email] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Parties]  WITH CHECK ADD  CONSTRAINT [EParty_CustomerLegalStatus] FOREIGN KEY([CustomerLegalStatusId])
REFERENCES [dbo].[CustomerLegalStatusConfigs] ([Id])
GO
ALTER TABLE [dbo].[Parties] CHECK CONSTRAINT [EParty_CustomerLegalStatus]
GO
ALTER TABLE [dbo].[Parties]  WITH CHECK ADD  CONSTRAINT [EParty_Language] FOREIGN KEY([LanguageId])
REFERENCES [dbo].[LanguageConfigs] ([Id])
GO
ALTER TABLE [dbo].[Parties] CHECK CONSTRAINT [EParty_Language]
GO
ALTER TABLE [dbo].[Parties]  WITH CHECK ADD  CONSTRAINT [EParty_ParentParty] FOREIGN KEY([ParentPartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[Parties] CHECK CONSTRAINT [EParty_ParentParty]
GO
ALTER TABLE [dbo].[Parties]  WITH CHECK ADD  CONSTRAINT [EParty_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[Parties] CHECK CONSTRAINT [EParty_Portfolio]
GO
ALTER TABLE [dbo].[Parties]  WITH CHECK ADD  CONSTRAINT [EParty_Professions] FOREIGN KEY([ProfessionsId])
REFERENCES [dbo].[ProfessionsConfigs] ([Id])
GO
ALTER TABLE [dbo].[Parties] CHECK CONSTRAINT [EParty_Professions]
GO
ALTER TABLE [dbo].[Parties]  WITH CHECK ADD  CONSTRAINT [EParty_Sector] FOREIGN KEY([SectorId])
REFERENCES [dbo].[SectorConfigs] ([Id])
GO
ALTER TABLE [dbo].[Parties] CHECK CONSTRAINT [EParty_Sector]
GO
ALTER TABLE [dbo].[Parties]  WITH CHECK ADD  CONSTRAINT [EParty_StateOfIncorporation] FOREIGN KEY([StateOfIncorporationId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[Parties] CHECK CONSTRAINT [EParty_StateOfIncorporation]
GO
