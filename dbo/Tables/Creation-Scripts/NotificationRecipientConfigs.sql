SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NotificationRecipientConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[NotifyTxnSubscribersOnly] [bit] NOT NULL,
	[Condition] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[RecipientType] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[UserExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NULL,
	[UserGroupId] [bigint] NULL,
	[NotificationConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[EmailTemplateId] [bigint] NULL,
	[OverrideEmailNotification] [bit] NOT NULL,
	[IsMultipleUser] [bit] NOT NULL,
	[ExternalEmailSelectionSQL] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[FromEmailExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[FromEmail] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[NotificationRecipientConfigs]  WITH CHECK ADD  CONSTRAINT [ENotificationConfig_NotificationRecipientConfigs] FOREIGN KEY([NotificationConfigId])
REFERENCES [dbo].[NotificationConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[NotificationRecipientConfigs] CHECK CONSTRAINT [ENotificationConfig_NotificationRecipientConfigs]
GO
ALTER TABLE [dbo].[NotificationRecipientConfigs]  WITH CHECK ADD  CONSTRAINT [ENotificationRecipientConfig_EmailTemplate] FOREIGN KEY([EmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[NotificationRecipientConfigs] CHECK CONSTRAINT [ENotificationRecipientConfig_EmailTemplate]
GO
ALTER TABLE [dbo].[NotificationRecipientConfigs]  WITH CHECK ADD  CONSTRAINT [ENotificationRecipientConfig_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[NotificationRecipientConfigs] CHECK CONSTRAINT [ENotificationRecipientConfig_User]
GO
ALTER TABLE [dbo].[NotificationRecipientConfigs]  WITH CHECK ADD  CONSTRAINT [ENotificationRecipientConfig_UserGroup] FOREIGN KEY([UserGroupId])
REFERENCES [dbo].[UserGroups] ([Id])
GO
ALTER TABLE [dbo].[NotificationRecipientConfigs] CHECK CONSTRAINT [ENotificationRecipientConfig_UserGroup]
GO
