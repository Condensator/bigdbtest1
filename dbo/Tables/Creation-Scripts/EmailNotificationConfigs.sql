SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmailNotificationConfigs](
	[Id] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EmailTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EmailNotificationConfigs]  WITH CHECK ADD  CONSTRAINT [EEmailNotificationConfig_EmailTemplate] FOREIGN KEY([EmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[EmailNotificationConfigs] CHECK CONSTRAINT [EEmailNotificationConfig_EmailTemplate]
GO
ALTER TABLE [dbo].[EmailNotificationConfigs]  WITH CHECK ADD  CONSTRAINT [ENotificationConfig_EmailNotificationConfig] FOREIGN KEY([Id])
REFERENCES [dbo].[NotificationConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EmailNotificationConfigs] CHECK CONSTRAINT [ENotificationConfig_EmailNotificationConfig]
GO
