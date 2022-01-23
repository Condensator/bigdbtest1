SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditDecisionForCreditApplications](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[OpportunityId] [bigint] NOT NULL,
	[CreditDecisionId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsManual] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditDecisionForCreditApplications]  WITH CHECK ADD  CONSTRAINT [ECreditDecisionForCreditApplication_CreditDecision] FOREIGN KEY([CreditDecisionId])
REFERENCES [dbo].[CreditDecisions] ([Id])
GO
ALTER TABLE [dbo].[CreditDecisionForCreditApplications] CHECK CONSTRAINT [ECreditDecisionForCreditApplication_CreditDecision]
GO
ALTER TABLE [dbo].[CreditDecisionForCreditApplications]  WITH CHECK ADD  CONSTRAINT [EOpportunity_CreditDecisionForCreditApplications] FOREIGN KEY([OpportunityId])
REFERENCES [dbo].[Opportunities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditDecisionForCreditApplications] CHECK CONSTRAINT [EOpportunity_CreditDecisionForCreditApplications]
GO
