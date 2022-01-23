SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NotificationRecipients](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ToEmailId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NOT NULL,
	[CcEmailId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[BccEmailId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsFlaggedForSending] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NULL,
	[UserGroupId] [bigint] NULL,
	[ExternalRecipientId] [bigint] NULL,
	[NotificationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[NotificationRecipients]  WITH CHECK ADD  CONSTRAINT [ENotification_NotificationRecipients] FOREIGN KEY([NotificationId])
REFERENCES [dbo].[Notifications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[NotificationRecipients] CHECK CONSTRAINT [ENotification_NotificationRecipients]
GO
ALTER TABLE [dbo].[NotificationRecipients]  WITH CHECK ADD  CONSTRAINT [ENotificationRecipient_ExternalRecipient] FOREIGN KEY([ExternalRecipientId])
REFERENCES [dbo].[ExternalNotificationRecipients] ([Id])
GO
ALTER TABLE [dbo].[NotificationRecipients] CHECK CONSTRAINT [ENotificationRecipient_ExternalRecipient]
GO
ALTER TABLE [dbo].[NotificationRecipients]  WITH CHECK ADD  CONSTRAINT [ENotificationRecipient_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[NotificationRecipients] CHECK CONSTRAINT [ENotificationRecipient_User]
GO
ALTER TABLE [dbo].[NotificationRecipients]  WITH CHECK ADD  CONSTRAINT [ENotificationRecipient_UserGroup] FOREIGN KEY([UserGroupId])
REFERENCES [dbo].[UserGroups] ([Id])
GO
ALTER TABLE [dbo].[NotificationRecipients] CHECK CONSTRAINT [ENotificationRecipient_UserGroup]
GO
