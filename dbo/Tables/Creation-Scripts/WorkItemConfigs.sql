SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkItemConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Label] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Form] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[Duration] [bigint] NULL,
	[IsRemovable] [bit] NOT NULL,
	[IsRemove] [bit] NOT NULL,
	[IsOptional] [bit] NOT NULL,
	[IsNotify] [bit] NOT NULL,
	[IsNotifyOnAssignment] [bit] NOT NULL,
	[DummyEndStep] [bit] NOT NULL,
	[OverrideOwnerUser] [bit] NOT NULL,
	[IsOwnerUserRequired] [bit] NOT NULL,
	[AllowTossing] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TransactionStageConfigId] [bigint] NULL,
	[TransactionConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AcquireFromOtherUser] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[WorkItemConfigs]  WITH CHECK ADD  CONSTRAINT [ETransactionConfig_WorkItemConfigs] FOREIGN KEY([TransactionConfigId])
REFERENCES [dbo].[TransactionConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WorkItemConfigs] CHECK CONSTRAINT [ETransactionConfig_WorkItemConfigs]
GO
ALTER TABLE [dbo].[WorkItemConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkItemConfig_TransactionStageConfig] FOREIGN KEY([TransactionStageConfigId])
REFERENCES [dbo].[TransactionStageConfigs] ([Id])
GO
ALTER TABLE [dbo].[WorkItemConfigs] CHECK CONSTRAINT [EWorkItemConfig_TransactionStageConfig]
GO
