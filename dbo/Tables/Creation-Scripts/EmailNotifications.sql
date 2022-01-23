SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmailNotifications](
	[Id] [bigint] NOT NULL,
	[FromEmailId] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[Subject] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[Body] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[BodyTemplate_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[BodyTemplate_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[BodyTemplate_Content] [varbinary](82) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EmailNotifications]  WITH CHECK ADD  CONSTRAINT [ENotification_EmailNotification] FOREIGN KEY([Id])
REFERENCES [dbo].[Notifications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EmailNotifications] CHECK CONSTRAINT [ENotification_EmailNotification]
GO
