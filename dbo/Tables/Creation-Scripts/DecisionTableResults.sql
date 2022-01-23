SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DecisionTableResults](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ResultExpression] [nvarchar](4000) COLLATE Latin1_General_CI_AS NOT NULL,
	[ParameterId] [bigint] NOT NULL,
	[DecisionTableRuleId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[DecisionTableResults]  WITH CHECK ADD  CONSTRAINT [EDecisionTableResult_Parameter] FOREIGN KEY([ParameterId])
REFERENCES [dbo].[DecisionTableParameters] ([Id])
GO
ALTER TABLE [dbo].[DecisionTableResults] CHECK CONSTRAINT [EDecisionTableResult_Parameter]
GO
ALTER TABLE [dbo].[DecisionTableResults]  WITH CHECK ADD  CONSTRAINT [EDecisionTableRule_DecisionTableResults] FOREIGN KEY([DecisionTableRuleId])
REFERENCES [dbo].[DecisionTableRules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DecisionTableResults] CHECK CONSTRAINT [EDecisionTableRule_DecisionTableResults]
GO
