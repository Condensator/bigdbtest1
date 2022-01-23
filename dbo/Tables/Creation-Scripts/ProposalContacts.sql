SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProposalContacts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsNewAddress] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PartyAddressId] [bigint] NULL,
	[PartyContactId] [bigint] NOT NULL,
	[ProposalId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProposalContacts]  WITH CHECK ADD  CONSTRAINT [EProposal_ProposalContacts] FOREIGN KEY([ProposalId])
REFERENCES [dbo].[Proposals] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProposalContacts] CHECK CONSTRAINT [EProposal_ProposalContacts]
GO
ALTER TABLE [dbo].[ProposalContacts]  WITH CHECK ADD  CONSTRAINT [EProposalContact_PartyAddress] FOREIGN KEY([PartyAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[ProposalContacts] CHECK CONSTRAINT [EProposalContact_PartyAddress]
GO
ALTER TABLE [dbo].[ProposalContacts]  WITH CHECK ADD  CONSTRAINT [EProposalContact_PartyContact] FOREIGN KEY([PartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[ProposalContacts] CHECK CONSTRAINT [EProposalContact_PartyContact]
GO
