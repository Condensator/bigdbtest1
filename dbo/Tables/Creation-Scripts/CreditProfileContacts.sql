SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditProfileContacts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsNewAddress] [bit] NOT NULL,
	[IsNewContact] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PartyAddressId] [bigint] NULL,
	[PartyContactId] [bigint] NOT NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditProfileContacts]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditProfileContacts] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditProfileContacts] CHECK CONSTRAINT [ECreditProfile_CreditProfileContacts]
GO
ALTER TABLE [dbo].[CreditProfileContacts]  WITH CHECK ADD  CONSTRAINT [ECreditProfileContact_PartyAddress] FOREIGN KEY([PartyAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileContacts] CHECK CONSTRAINT [ECreditProfileContact_PartyAddress]
GO
ALTER TABLE [dbo].[CreditProfileContacts]  WITH CHECK ADD  CONSTRAINT [ECreditProfileContact_PartyContact] FOREIGN KEY([PartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileContacts] CHECK CONSTRAINT [ECreditProfileContact_PartyContact]
GO
