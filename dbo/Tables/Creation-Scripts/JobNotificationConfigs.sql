SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JobNotificationConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NotificationConfigId] [bigint] NOT NULL,
	[JobId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[JobNotificationConfigs]  WITH CHECK ADD  CONSTRAINT [EJob_JobNotificationConfigs] FOREIGN KEY([JobId])
REFERENCES [dbo].[Jobs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[JobNotificationConfigs] CHECK CONSTRAINT [EJob_JobNotificationConfigs]
GO
ALTER TABLE [dbo].[JobNotificationConfigs]  WITH CHECK ADD  CONSTRAINT [EJobNotificationConfig_NotificationConfig] FOREIGN KEY([NotificationConfigId])
REFERENCES [dbo].[NotificationConfigs] ([Id])
GO
ALTER TABLE [dbo].[JobNotificationConfigs] CHECK CONSTRAINT [EJobNotificationConfig_NotificationConfig]
GO
