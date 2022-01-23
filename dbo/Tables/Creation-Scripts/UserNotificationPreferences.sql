SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserNotificationPreferences](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsNotify] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EventId] [bigint] NOT NULL,
	[UserId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UserNotificationPreferences]  WITH CHECK ADD  CONSTRAINT [EUser_UserNotificationPreferences] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserNotificationPreferences] CHECK CONSTRAINT [EUser_UserNotificationPreferences]
GO
ALTER TABLE [dbo].[UserNotificationPreferences]  WITH CHECK ADD  CONSTRAINT [EUserNotificationPreference_Event] FOREIGN KEY([EventId])
REFERENCES [dbo].[NotificationEventConfigs] ([Id])
GO
ALTER TABLE [dbo].[UserNotificationPreferences] CHECK CONSTRAINT [EUserNotificationPreference_Event]
GO
