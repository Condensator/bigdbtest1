SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RemitToes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Code] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UniqueIdentifier] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[WireType] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsSecuredParty] [bit] NOT NULL,
	[IsPrivateLabel] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityContactId] [bigint] NULL,
	[LegalEntityAddressId] [bigint] NULL,
	[PartyContactId] [bigint] NULL,
	[PartyAddressId] [bigint] NULL,
	[UserGroupId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LogoId] [bigint] NULL,
	[DefaultFromEmail] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFooterText] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RemitToes]  WITH CHECK ADD  CONSTRAINT [ERemitTo_LegalEntityAddress] FOREIGN KEY([LegalEntityAddressId])
REFERENCES [dbo].[LegalEntityAddresses] ([Id])
GO
ALTER TABLE [dbo].[RemitToes] CHECK CONSTRAINT [ERemitTo_LegalEntityAddress]
GO
ALTER TABLE [dbo].[RemitToes]  WITH CHECK ADD  CONSTRAINT [ERemitTo_LegalEntityContact] FOREIGN KEY([LegalEntityContactId])
REFERENCES [dbo].[LegalEntityContacts] ([Id])
GO
ALTER TABLE [dbo].[RemitToes] CHECK CONSTRAINT [ERemitTo_LegalEntityContact]
GO
ALTER TABLE [dbo].[RemitToes]  WITH CHECK ADD  CONSTRAINT [ERemitTo_Logo] FOREIGN KEY([LogoId])
REFERENCES [dbo].[Logoes] ([Id])
GO
ALTER TABLE [dbo].[RemitToes] CHECK CONSTRAINT [ERemitTo_Logo]
GO
ALTER TABLE [dbo].[RemitToes]  WITH CHECK ADD  CONSTRAINT [ERemitTo_PartyAddress] FOREIGN KEY([PartyAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[RemitToes] CHECK CONSTRAINT [ERemitTo_PartyAddress]
GO
ALTER TABLE [dbo].[RemitToes]  WITH CHECK ADD  CONSTRAINT [ERemitTo_PartyContact] FOREIGN KEY([PartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[RemitToes] CHECK CONSTRAINT [ERemitTo_PartyContact]
GO
ALTER TABLE [dbo].[RemitToes]  WITH CHECK ADD  CONSTRAINT [ERemitTo_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[RemitToes] CHECK CONSTRAINT [ERemitTo_Portfolio]
GO
ALTER TABLE [dbo].[RemitToes]  WITH CHECK ADD  CONSTRAINT [ERemitTo_UserGroup] FOREIGN KEY([UserGroupId])
REFERENCES [dbo].[UserGroups] ([Id])
GO
ALTER TABLE [dbo].[RemitToes] CHECK CONSTRAINT [ERemitTo_UserGroup]
GO
