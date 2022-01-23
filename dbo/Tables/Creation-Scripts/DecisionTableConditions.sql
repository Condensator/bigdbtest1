SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DecisionTableConditions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Operator] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[FromValue] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ToValue] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[DecisionTableRuleId] [bigint] NOT NULL,
	[ParameterId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DecisionTableConditions]  WITH CHECK ADD  CONSTRAINT [EDecisionTableCondition_Parameter] FOREIGN KEY([ParameterId])
REFERENCES [dbo].[DecisionTableParameters] ([Id])
GO
ALTER TABLE [dbo].[DecisionTableConditions] CHECK CONSTRAINT [EDecisionTableCondition_Parameter]
GO
ALTER TABLE [dbo].[DecisionTableConditions]  WITH CHECK ADD  CONSTRAINT [EDecisionTableRule_DecisionTableConditions] FOREIGN KEY([DecisionTableRuleId])
REFERENCES [dbo].[DecisionTableRules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DecisionTableConditions] CHECK CONSTRAINT [EDecisionTableRule_DecisionTableConditions]
GO
