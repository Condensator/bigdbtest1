SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkFlowHistoryRelatedEntityTransactionConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TransactionConfigId] [bigint] NOT NULL,
	[WorkFlowHistoryRelatedEntityConfigId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[WorkFlowHistoryRelatedEntityTransactionConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkFlowHistoryRelatedEntityConfig_WorkFlowHistoryRelatedEntityTransactionConfigs] FOREIGN KEY([WorkFlowHistoryRelatedEntityConfigId])
REFERENCES [dbo].[WorkFlowHistoryRelatedEntityConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WorkFlowHistoryRelatedEntityTransactionConfigs] CHECK CONSTRAINT [EWorkFlowHistoryRelatedEntityConfig_WorkFlowHistoryRelatedEntityTransactionConfigs]
GO
ALTER TABLE [dbo].[WorkFlowHistoryRelatedEntityTransactionConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkFlowHistoryRelatedEntityTransactionConfig_TransactionConfig] FOREIGN KEY([TransactionConfigId])
REFERENCES [dbo].[TransactionConfigs] ([Id])
GO
ALTER TABLE [dbo].[WorkFlowHistoryRelatedEntityTransactionConfigs] CHECK CONSTRAINT [EWorkFlowHistoryRelatedEntityTransactionConfig_TransactionConfig]
GO
