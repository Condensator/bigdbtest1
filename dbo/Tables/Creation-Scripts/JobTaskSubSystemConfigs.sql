SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JobTaskSubSystemConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SubSystemId] [bigint] NOT NULL,
	[JobTaskConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[JobTaskSubSystemConfigs]  WITH CHECK ADD  CONSTRAINT [EJobTaskConfig_JobTaskSubSystemConfigs] FOREIGN KEY([JobTaskConfigId])
REFERENCES [dbo].[JobTaskConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[JobTaskSubSystemConfigs] CHECK CONSTRAINT [EJobTaskConfig_JobTaskSubSystemConfigs]
GO
ALTER TABLE [dbo].[JobTaskSubSystemConfigs]  WITH CHECK ADD  CONSTRAINT [EJobTaskSubSystemConfig_SubSystem] FOREIGN KEY([SubSystemId])
REFERENCES [dbo].[SubSystemConfigs] ([Id])
GO
ALTER TABLE [dbo].[JobTaskSubSystemConfigs] CHECK CONSTRAINT [EJobTaskSubSystemConfig_SubSystem]
GO
