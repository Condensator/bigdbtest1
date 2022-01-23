SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Notifications](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[AsOfDate] [datetimeoffset](7) NULL,
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EntityId] [bigint] NULL,
	[SourceModule] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[SourceId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NotificationRecipientConfigId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[EvaluateContentAtRuntime] [bit] NOT NULL,
	[TransactionInstanceId] [bigint] NULL,
	[WorkItemId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Notifications]  WITH CHECK ADD  CONSTRAINT [ENotification_NotificationRecipientConfig] FOREIGN KEY([NotificationRecipientConfigId])
REFERENCES [dbo].[NotificationRecipientConfigs] ([Id])
GO
ALTER TABLE [dbo].[Notifications] CHECK CONSTRAINT [ENotification_NotificationRecipientConfig]
GO
