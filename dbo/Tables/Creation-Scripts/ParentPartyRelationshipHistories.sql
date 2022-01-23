SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ParentPartyRelationshipHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssignedDate] [date] NOT NULL,
	[UnassignedDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ParentPartyId] [bigint] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ParentPartyRelationshipHistories]  WITH CHECK ADD  CONSTRAINT [EParentPartyRelationshipHistory_ParentParty] FOREIGN KEY([ParentPartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[ParentPartyRelationshipHistories] CHECK CONSTRAINT [EParentPartyRelationshipHistory_ParentParty]
GO
ALTER TABLE [dbo].[ParentPartyRelationshipHistories]  WITH CHECK ADD  CONSTRAINT [EParty_ParentPartyRelationshipHistories] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ParentPartyRelationshipHistories] CHECK CONSTRAINT [EParty_ParentPartyRelationshipHistories]
GO
