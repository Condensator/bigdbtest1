SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityStatusRequirementConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActivityTypeId] [bigint] NOT NULL,
	[StatusId] [bigint] NOT NULL,
	[ActionId] [bigint] NOT NULL,
	[TransactionConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityStatusRequirementConfigs]  WITH CHECK ADD  CONSTRAINT [EActivityStatusRequirementConfig_Action] FOREIGN KEY([ActionId])
REFERENCES [dbo].[WorkItemActionConfigs] ([Id])
GO
ALTER TABLE [dbo].[ActivityStatusRequirementConfigs] CHECK CONSTRAINT [EActivityStatusRequirementConfig_Action]
GO
ALTER TABLE [dbo].[ActivityStatusRequirementConfigs]  WITH CHECK ADD  CONSTRAINT [EActivityStatusRequirementConfig_ActivityType] FOREIGN KEY([ActivityTypeId])
REFERENCES [dbo].[ActivityTypes] ([Id])
GO
ALTER TABLE [dbo].[ActivityStatusRequirementConfigs] CHECK CONSTRAINT [EActivityStatusRequirementConfig_ActivityType]
GO
ALTER TABLE [dbo].[ActivityStatusRequirementConfigs]  WITH CHECK ADD  CONSTRAINT [EActivityStatusRequirementConfig_Status] FOREIGN KEY([StatusId])
REFERENCES [dbo].[ActivityStatusForTypes] ([Id])
GO
ALTER TABLE [dbo].[ActivityStatusRequirementConfigs] CHECK CONSTRAINT [EActivityStatusRequirementConfig_Status]
GO
ALTER TABLE [dbo].[ActivityStatusRequirementConfigs]  WITH CHECK ADD  CONSTRAINT [ETransactionConfig_ActivityStatusRequirementConfigs] FOREIGN KEY([TransactionConfigId])
REFERENCES [dbo].[TransactionConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityStatusRequirementConfigs] CHECK CONSTRAINT [ETransactionConfig_ActivityStatusRequirementConfigs]
GO
