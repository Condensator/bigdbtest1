SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProposalSyndicationFundingSources](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ParticipationPercentage] [decimal](18, 8) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FunderId] [bigint] NOT NULL,
	[ProposalId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProposalSyndicationFundingSources]  WITH CHECK ADD  CONSTRAINT [EProposal_ProposalSyndicationFundingSources] FOREIGN KEY([ProposalId])
REFERENCES [dbo].[Proposals] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProposalSyndicationFundingSources] CHECK CONSTRAINT [EProposal_ProposalSyndicationFundingSources]
GO
ALTER TABLE [dbo].[ProposalSyndicationFundingSources]  WITH CHECK ADD  CONSTRAINT [EProposalSyndicationFundingSource_Funder] FOREIGN KEY([FunderId])
REFERENCES [dbo].[Funders] ([Id])
GO
ALTER TABLE [dbo].[ProposalSyndicationFundingSources] CHECK CONSTRAINT [EProposalSyndicationFundingSource_Funder]
GO
