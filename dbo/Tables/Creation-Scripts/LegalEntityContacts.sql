SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalEntityContacts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
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
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MailingAddressId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LastName2] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UniqueIdentifier] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalEntityContacts]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_LegalEntityContacts] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LegalEntityContacts] CHECK CONSTRAINT [ELegalEntity_LegalEntityContacts]
GO
ALTER TABLE [dbo].[LegalEntityContacts]  WITH CHECK ADD  CONSTRAINT [ELegalEntityContact_MailingAddress] FOREIGN KEY([MailingAddressId])
REFERENCES [dbo].[LegalEntityAddresses] ([Id])
GO
ALTER TABLE [dbo].[LegalEntityContacts] CHECK CONSTRAINT [ELegalEntityContact_MailingAddress]
GO
