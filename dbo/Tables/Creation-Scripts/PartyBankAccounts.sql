SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PartyBankAccounts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BankAccountId] [bigint] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustomerPortalUserId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PartyBankAccounts]  WITH CHECK ADD  CONSTRAINT [EParty_PartyBankAccounts] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PartyBankAccounts] CHECK CONSTRAINT [EParty_PartyBankAccounts]
GO
ALTER TABLE [dbo].[PartyBankAccounts]  WITH CHECK ADD  CONSTRAINT [EPartyBankAccount_BankAccount] FOREIGN KEY([BankAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[PartyBankAccounts] CHECK CONSTRAINT [EPartyBankAccount_BankAccount]
GO
ALTER TABLE [dbo].[PartyBankAccounts]  WITH CHECK ADD  CONSTRAINT [EPartyBankAccount_CustomerPortalUser] FOREIGN KEY([CustomerPortalUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[PartyBankAccounts] CHECK CONSTRAINT [EPartyBankAccount_CustomerPortalUser]
GO
