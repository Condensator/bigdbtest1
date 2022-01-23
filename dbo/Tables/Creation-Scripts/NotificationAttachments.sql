SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NotificationAttachments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Attachment_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Content] [varbinary](82) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NotificationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[NotificationAttachments]  WITH CHECK ADD  CONSTRAINT [ENotification_NotificationAttachments] FOREIGN KEY([NotificationId])
REFERENCES [dbo].[Notifications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[NotificationAttachments] CHECK CONSTRAINT [ENotification_NotificationAttachments]
GO
