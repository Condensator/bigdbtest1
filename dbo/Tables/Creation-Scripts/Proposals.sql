SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Proposals](
	[Id] [bigint] NOT NULL,
	[OpportunityAmount_Amount] [decimal](16, 2) NOT NULL,
	[OpportunityAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AnticipatedFeeToSource_Amount] [decimal](16, 2) NULL,
	[AnticipatedFeeToSource_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TransactionDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsPreApproved] [bit] NOT NULL,
	[IsSyndicated] [bit] NOT NULL,
	[SyndicationStrategy] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsDataGatheringComplete] [bit] NOT NULL,
	[IsCreditOrAMProposal] [bit] NOT NULL,
	[Status] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PreApprovalLOCId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DocumentMethod] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Proposals]  WITH CHECK ADD  CONSTRAINT [EOpportunity_Proposal] FOREIGN KEY([Id])
REFERENCES [dbo].[Opportunities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Proposals] CHECK CONSTRAINT [EOpportunity_Proposal]
GO
ALTER TABLE [dbo].[Proposals]  WITH CHECK ADD  CONSTRAINT [EProposal_PreApprovalLOC] FOREIGN KEY([PreApprovalLOCId])
REFERENCES [dbo].[CreditProfiles] ([Id])
GO
ALTER TABLE [dbo].[Proposals] CHECK CONSTRAINT [EProposal_PreApprovalLOC]
GO
