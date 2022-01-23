SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PartyContacts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[UniqueIdentifier] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[Prefix] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[FirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[MiddleName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[FullName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[PhoneNumber1] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ExtensionNumber1] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[PhoneNumber2] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ExtensionNumber2] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[MobilePhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[FaxNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[EMailId] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[DateOfBirth] [date] MASKED WITH (FUNCTION = 'default()') NULL,
	[OwnershipPercentage] [decimal](5, 2) NULL,
	[CIPDocumentSourceForName] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[CIPDocumentSourceForAddress] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[CIPDocumentSourceForTaxIdOrSSN] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[MortgageHighCredit_Amount] [decimal](16, 2) NULL,
	[MortgageHighCredit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsSCRA] [bit] NOT NULL,
	[SCRAStartDate] [date] NULL,
	[SCRAEndDate] [date] NULL,
	[BenefitsAndProtection] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[IsFromAssumption] [bit] NOT NULL,
	[IsAssumptionApproved] [bit] NOT NULL,
	[ParalegalName] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[SecretaryName] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[Webpage] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MailingAddressId] [bigint] NULL,
	[ParentPartyContactId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[PartyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LastName2] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SFDCContactId] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[LastFourDigitSocialSecurityNumber] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[SocialSecurityNumber_CT] [varbinary](48) NULL,
	[IsBookingNotificationAllowed] [bit] NOT NULL,
	[IsCreditNotificationAllowed] [bit] NOT NULL,
	[CIPDocumentSourceNameId] [bigint] NULL,
	[TimeZoneId] [bigint] NULL,
	[BusinessStartTimeInHours] [int] NOT NULL,
	[BusinessEndTimeInHours] [int] NOT NULL,
	[BusinessStartTimeInMinutes] [int] NOT NULL,
	[BusinessEndTimeInMinutes] [int] NOT NULL,
	[EGNNumber_CT] [varbinary](64) NULL,
	[PowerOfAttorneyNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PowerOfAttorneyValidity] [date] NULL,
	[Notary] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RegistarationNoOfNotary] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DrivingLicense] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IssuedOn] [date] NULL,
	[IssuedIn] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Validity] [date] NULL,
	[Foreigner] [bit] NOT NULL,
	[IDCardNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IDCardIssuedOn] [date] NULL,
	[IDCardIssuedIn] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Gender] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[LN4] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PassportNo] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PassportIssuedOn] [date] NULL,
	[PassportAddress] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[EMail2] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[NationalIdCardNumber_CT] [varbinary](64) NULL,
	[PassportCountry] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PartyContacts]  WITH CHECK ADD  CONSTRAINT [EParty_PartyContacts] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PartyContacts] CHECK CONSTRAINT [EParty_PartyContacts]
GO
ALTER TABLE [dbo].[PartyContacts]  WITH CHECK ADD  CONSTRAINT [EPartyContact_CIPDocumentSourceName] FOREIGN KEY([CIPDocumentSourceNameId])
REFERENCES [dbo].[CIPDocumentSourceConfigs] ([Id])
GO
ALTER TABLE [dbo].[PartyContacts] CHECK CONSTRAINT [EPartyContact_CIPDocumentSourceName]
GO
ALTER TABLE [dbo].[PartyContacts]  WITH CHECK ADD  CONSTRAINT [EPartyContact_MailingAddress] FOREIGN KEY([MailingAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[PartyContacts] CHECK CONSTRAINT [EPartyContact_MailingAddress]
GO
ALTER TABLE [dbo].[PartyContacts]  WITH CHECK ADD  CONSTRAINT [EPartyContact_ParentPartyContact] FOREIGN KEY([ParentPartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[PartyContacts] CHECK CONSTRAINT [EPartyContact_ParentPartyContact]
GO
ALTER TABLE [dbo].[PartyContacts]  WITH CHECK ADD  CONSTRAINT [EPartyContact_TimeZone] FOREIGN KEY([TimeZoneId])
REFERENCES [dbo].[TimeZones] ([Id])
GO
ALTER TABLE [dbo].[PartyContacts] CHECK CONSTRAINT [EPartyContact_TimeZone]
GO
ALTER TABLE [dbo].[PartyContacts]  WITH CHECK ADD  CONSTRAINT [EPartyContact_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[PartyContacts] CHECK CONSTRAINT [EPartyContact_Vendor]
GO
