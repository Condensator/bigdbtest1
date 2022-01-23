SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditApplicationContacts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsNewAddress] [bit] NOT NULL,
	[IsNewContact] [bit] NOT NULL,
	[IsVendorDetailRequired] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PartyAddressId] [bigint] NULL,
	[PartyContactId] [bigint] NOT NULL,
	[CreditApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditApplicationContacts]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_CreditApplicationContacts] FOREIGN KEY([CreditApplicationId])
REFERENCES [dbo].[CreditApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditApplicationContacts] CHECK CONSTRAINT [ECreditApplication_CreditApplicationContacts]
GO
ALTER TABLE [dbo].[CreditApplicationContacts]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationContact_PartyAddress] FOREIGN KEY([PartyAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationContacts] CHECK CONSTRAINT [ECreditApplicationContact_PartyAddress]
GO
ALTER TABLE [dbo].[CreditApplicationContacts]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationContact_PartyContact] FOREIGN KEY([PartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationContacts] CHECK CONSTRAINT [ECreditApplicationContact_PartyContact]
GO
