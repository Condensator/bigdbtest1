SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkItemNotificationConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NotificationConfigId] [bigint] NOT NULL,
	[WorkItemConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[WorkItemNotificationConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkItemConfig_WorkItemNotificationConfigs] FOREIGN KEY([WorkItemConfigId])
REFERENCES [dbo].[WorkItemConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WorkItemNotificationConfigs] CHECK CONSTRAINT [EWorkItemConfig_WorkItemNotificationConfigs]
GO
ALTER TABLE [dbo].[WorkItemNotificationConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkItemNotificationConfig_NotificationConfig] FOREIGN KEY([NotificationConfigId])
REFERENCES [dbo].[NotificationConfigs] ([Id])
GO
ALTER TABLE [dbo].[WorkItemNotificationConfigs] CHECK CONSTRAINT [EWorkItemNotificationConfig_NotificationConfig]
GO
