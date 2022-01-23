SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PartyTaxRegistrationDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[CountryId] [bigint] NOT NULL,
	[StateId] [bigint] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxRegistrationName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxRegistrationId] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PartyTaxRegistrationDetails]  WITH CHECK ADD  CONSTRAINT [EParty_PartyTaxRegistrationDetails] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PartyTaxRegistrationDetails] CHECK CONSTRAINT [EParty_PartyTaxRegistrationDetails]
GO
ALTER TABLE [dbo].[PartyTaxRegistrationDetails]  WITH CHECK ADD  CONSTRAINT [EPartyTaxRegistrationDetail_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[PartyTaxRegistrationDetails] CHECK CONSTRAINT [EPartyTaxRegistrationDetail_Country]
GO
ALTER TABLE [dbo].[PartyTaxRegistrationDetails]  WITH CHECK ADD  CONSTRAINT [EPartyTaxRegistrationDetail_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[PartyTaxRegistrationDetails] CHECK CONSTRAINT [EPartyTaxRegistrationDetail_State]
GO
