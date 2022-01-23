SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TransactionNotificationConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NotificationConfigId] [bigint] NOT NULL,
	[TransactionConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TransactionNotificationConfigs]  WITH CHECK ADD  CONSTRAINT [ETransactionConfig_TransactionNotificationConfigs] FOREIGN KEY([TransactionConfigId])
REFERENCES [dbo].[TransactionConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TransactionNotificationConfigs] CHECK CONSTRAINT [ETransactionConfig_TransactionNotificationConfigs]
GO
ALTER TABLE [dbo].[TransactionNotificationConfigs]  WITH CHECK ADD  CONSTRAINT [ETransactionNotificationConfig_NotificationConfig] FOREIGN KEY([NotificationConfigId])
REFERENCES [dbo].[NotificationConfigs] ([Id])
GO
ALTER TABLE [dbo].[TransactionNotificationConfigs] CHECK CONSTRAINT [ETransactionNotificationConfig_NotificationConfig]
GO
