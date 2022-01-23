SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkItemSubSystemConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Form] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SubSystemId] [bigint] NOT NULL,
	[WorkItemConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Viewable] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[WorkItemSubSystemConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkItemConfig_WorkItemSubSystemConfigs] FOREIGN KEY([WorkItemConfigId])
REFERENCES [dbo].[WorkItemConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WorkItemSubSystemConfigs] CHECK CONSTRAINT [EWorkItemConfig_WorkItemSubSystemConfigs]
GO
ALTER TABLE [dbo].[WorkItemSubSystemConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkItemSubSystemConfig_SubSystem] FOREIGN KEY([SubSystemId])
REFERENCES [dbo].[SubSystemConfigs] ([Id])
GO
ALTER TABLE [dbo].[WorkItemSubSystemConfigs] CHECK CONSTRAINT [EWorkItemSubSystemConfig_SubSystem]
GO
