SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityRequirementConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActivityGroupId] [bigint] NOT NULL,
	[WorkItemConfigId] [bigint] NOT NULL,
	[TransactionConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityRequirementConfigs]  WITH CHECK ADD  CONSTRAINT [EActivityRequirementConfig_ActivityGroup] FOREIGN KEY([ActivityGroupId])
REFERENCES [dbo].[ActivityGroups] ([Id])
GO
ALTER TABLE [dbo].[ActivityRequirementConfigs] CHECK CONSTRAINT [EActivityRequirementConfig_ActivityGroup]
GO
ALTER TABLE [dbo].[ActivityRequirementConfigs]  WITH CHECK ADD  CONSTRAINT [EActivityRequirementConfig_WorkItemConfig] FOREIGN KEY([WorkItemConfigId])
REFERENCES [dbo].[WorkItemConfigs] ([Id])
GO
ALTER TABLE [dbo].[ActivityRequirementConfigs] CHECK CONSTRAINT [EActivityRequirementConfig_WorkItemConfig]
GO
ALTER TABLE [dbo].[ActivityRequirementConfigs]  WITH CHECK ADD  CONSTRAINT [ETransactionConfig_ActivityRequirementConfigs] FOREIGN KEY([TransactionConfigId])
REFERENCES [dbo].[TransactionConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityRequirementConfigs] CHECK CONSTRAINT [ETransactionConfig_ActivityRequirementConfigs]
GO
