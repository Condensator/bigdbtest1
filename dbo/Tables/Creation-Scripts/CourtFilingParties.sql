SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CourtFilingParties](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PartyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Role] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[DateServed] [date] NULL,
	[AnswerDeadlineDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[IsMainParty] [bit] NOT NULL,
	[PartyTypes] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[IsDeletedRecord] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ThirdPartyRelationshipId] [bigint] NULL,
	[PartyId] [bigint] NULL,
	[RelatedCustomerId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[CourtFilingId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CourtFilingParties]  WITH CHECK ADD  CONSTRAINT [ECourtFiling_CourtFilingParties] FOREIGN KEY([CourtFilingId])
REFERENCES [dbo].[CourtFilings] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CourtFilingParties] CHECK CONSTRAINT [ECourtFiling_CourtFilingParties]
GO
ALTER TABLE [dbo].[CourtFilingParties]  WITH CHECK ADD  CONSTRAINT [ECourtFilingParty_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[CourtFilingParties] CHECK CONSTRAINT [ECourtFilingParty_LegalEntity]
GO
ALTER TABLE [dbo].[CourtFilingParties]  WITH CHECK ADD  CONSTRAINT [ECourtFilingParty_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[CourtFilingParties] CHECK CONSTRAINT [ECourtFilingParty_Party]
GO
ALTER TABLE [dbo].[CourtFilingParties]  WITH CHECK ADD  CONSTRAINT [ECourtFilingParty_RelatedCustomer] FOREIGN KEY([RelatedCustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[CourtFilingParties] CHECK CONSTRAINT [ECourtFilingParty_RelatedCustomer]
GO
ALTER TABLE [dbo].[CourtFilingParties]  WITH CHECK ADD  CONSTRAINT [ECourtFilingParty_ThirdPartyRelationship] FOREIGN KEY([ThirdPartyRelationshipId])
REFERENCES [dbo].[CustomerThirdPartyRelationships] ([Id])
GO
ALTER TABLE [dbo].[CourtFilingParties] CHECK CONSTRAINT [ECourtFilingParty_ThirdPartyRelationship]
GO
