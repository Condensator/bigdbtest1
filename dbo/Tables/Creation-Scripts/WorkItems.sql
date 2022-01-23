SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkItems](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[Status] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[StartDate] [datetimeoffset](7) NULL,
	[EndDate] [datetimeoffset](7) NULL,
	[DueDate] [datetimeoffset](7) NULL,
	[Comment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[CompletionComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[FollowupDate] [date] NULL,
	[LateNotificationCount] [int] NOT NULL,
	[ActionName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Duration] [bigint] NULL,
	[IsOptional] [bit] NOT NULL,
	[IsCanceledByUser] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[WorkItemConfigId] [bigint] NOT NULL,
	[TransactionInstanceId] [bigint] NULL,
	[OwnerUserId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[WorkItems]  WITH CHECK ADD  CONSTRAINT [EWorkItem_OwnerUser] FOREIGN KEY([OwnerUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[WorkItems] CHECK CONSTRAINT [EWorkItem_OwnerUser]
GO
ALTER TABLE [dbo].[WorkItems]  WITH CHECK ADD  CONSTRAINT [EWorkItem_TransactionInstance] FOREIGN KEY([TransactionInstanceId])
REFERENCES [dbo].[TransactionInstances] ([Id])
GO
ALTER TABLE [dbo].[WorkItems] CHECK CONSTRAINT [EWorkItem_TransactionInstance]
GO
ALTER TABLE [dbo].[WorkItems]  WITH CHECK ADD  CONSTRAINT [EWorkItem_WorkItemConfig] FOREIGN KEY([WorkItemConfigId])
REFERENCES [dbo].[WorkItemConfigs] ([Id])
GO
ALTER TABLE [dbo].[WorkItems] CHECK CONSTRAINT [EWorkItem_WorkItemConfig]
GO
