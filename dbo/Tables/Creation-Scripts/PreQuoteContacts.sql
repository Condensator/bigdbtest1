SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreQuoteContacts](
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
	[PreQuoteId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PreQuoteContacts]  WITH CHECK ADD  CONSTRAINT [EPreQuote_PreQuoteContacts] FOREIGN KEY([PreQuoteId])
REFERENCES [dbo].[PreQuotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PreQuoteContacts] CHECK CONSTRAINT [EPreQuote_PreQuoteContacts]
GO
ALTER TABLE [dbo].[PreQuoteContacts]  WITH CHECK ADD  CONSTRAINT [EPreQuoteContact_PartyAddress] FOREIGN KEY([PartyAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteContacts] CHECK CONSTRAINT [EPreQuoteContact_PartyAddress]
GO
ALTER TABLE [dbo].[PreQuoteContacts]  WITH CHECK ADD  CONSTRAINT [EPreQuoteContact_PartyContact] FOREIGN KEY([PartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteContacts] CHECK CONSTRAINT [EPreQuoteContact_PartyContact]
GO
