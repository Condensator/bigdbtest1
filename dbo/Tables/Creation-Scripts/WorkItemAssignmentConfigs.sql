SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkItemAssignmentConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Condition] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[AssignmentType] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[UserExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[UserGroupExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[SequenceNumber] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SpecificWorkItemId] [bigint] NULL,
	[UserId] [bigint] NULL,
	[UserGroupId] [bigint] NULL,
	[WorkItemConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsMultipleUser] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[WorkItemAssignmentConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkItemAssignmentConfig_SpecificWorkItem] FOREIGN KEY([SpecificWorkItemId])
REFERENCES [dbo].[WorkItemConfigs] ([Id])
GO
ALTER TABLE [dbo].[WorkItemAssignmentConfigs] CHECK CONSTRAINT [EWorkItemAssignmentConfig_SpecificWorkItem]
GO
ALTER TABLE [dbo].[WorkItemAssignmentConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkItemAssignmentConfig_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[WorkItemAssignmentConfigs] CHECK CONSTRAINT [EWorkItemAssignmentConfig_User]
GO
ALTER TABLE [dbo].[WorkItemAssignmentConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkItemAssignmentConfig_UserGroup] FOREIGN KEY([UserGroupId])
REFERENCES [dbo].[UserGroups] ([Id])
GO
ALTER TABLE [dbo].[WorkItemAssignmentConfigs] CHECK CONSTRAINT [EWorkItemAssignmentConfig_UserGroup]
GO
ALTER TABLE [dbo].[WorkItemAssignmentConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkItemConfig_WorkItemAssignmentConfigs] FOREIGN KEY([WorkItemConfigId])
REFERENCES [dbo].[WorkItemConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WorkItemAssignmentConfigs] CHECK CONSTRAINT [EWorkItemConfig_WorkItemAssignmentConfigs]
GO
