SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProposalThirdPartyRelationships](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RelationshipPercentage] [decimal](5, 2) NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ThirdPartyRelationshipId] [bigint] NOT NULL,
	[ProposalId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProposalThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [EProposal_ProposalThirdPartyRelationships] FOREIGN KEY([ProposalId])
REFERENCES [dbo].[Proposals] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProposalThirdPartyRelationships] CHECK CONSTRAINT [EProposal_ProposalThirdPartyRelationships]
GO
ALTER TABLE [dbo].[ProposalThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [EProposalThirdPartyRelationship_ThirdPartyRelationship] FOREIGN KEY([ThirdPartyRelationshipId])
REFERENCES [dbo].[CustomerThirdPartyRelationships] ([Id])
GO
ALTER TABLE [dbo].[ProposalThirdPartyRelationships] CHECK CONSTRAINT [EProposalThirdPartyRelationship_ThirdPartyRelationship]
GO
