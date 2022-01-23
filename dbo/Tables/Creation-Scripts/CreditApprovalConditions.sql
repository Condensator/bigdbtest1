SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditApprovalConditions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ApprovalConditionConfigId] [bigint] NULL,
	[CreditDecisionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CreditApprovalCondition] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditApprovalConditions]  WITH CHECK ADD  CONSTRAINT [ECreditApprovalCondition_ApprovalConditionConfig] FOREIGN KEY([ApprovalConditionConfigId])
REFERENCES [dbo].[ApprovalConditionConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditApprovalConditions] CHECK CONSTRAINT [ECreditApprovalCondition_ApprovalConditionConfig]
GO
ALTER TABLE [dbo].[CreditApprovalConditions]  WITH CHECK ADD  CONSTRAINT [ECreditDecision_CreditApprovalConditions] FOREIGN KEY([CreditDecisionId])
REFERENCES [dbo].[CreditDecisions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditApprovalConditions] CHECK CONSTRAINT [ECreditDecision_CreditApprovalConditions]
GO
