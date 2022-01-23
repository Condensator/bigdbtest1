SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EventInstanceJobTaskMappings](
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobTaskConfigId] [bigint] NOT NULL,
	[JobStepId] [bigint] NOT NULL,
	[JobId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EventInstanceJobTaskMappings]  WITH CHECK ADD  CONSTRAINT [EEventInstance_EventInstanceJobTaskMapping] FOREIGN KEY([Id])
REFERENCES [dbo].[EventInstances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EventInstanceJobTaskMappings] CHECK CONSTRAINT [EEventInstance_EventInstanceJobTaskMapping]
GO
ALTER TABLE [dbo].[EventInstanceJobTaskMappings]  WITH CHECK ADD  CONSTRAINT [EEventInstanceJobTaskMapping_Job] FOREIGN KEY([JobId])
REFERENCES [dbo].[Jobs] ([Id])
GO
ALTER TABLE [dbo].[EventInstanceJobTaskMappings] CHECK CONSTRAINT [EEventInstanceJobTaskMapping_Job]
GO
ALTER TABLE [dbo].[EventInstanceJobTaskMappings]  WITH CHECK ADD  CONSTRAINT [EEventInstanceJobTaskMapping_JobStep] FOREIGN KEY([JobStepId])
REFERENCES [dbo].[JobSteps] ([Id])
GO
ALTER TABLE [dbo].[EventInstanceJobTaskMappings] CHECK CONSTRAINT [EEventInstanceJobTaskMapping_JobStep]
GO
ALTER TABLE [dbo].[EventInstanceJobTaskMappings]  WITH CHECK ADD  CONSTRAINT [EEventInstanceJobTaskMapping_JobTaskConfig] FOREIGN KEY([JobTaskConfigId])
REFERENCES [dbo].[JobTaskConfigs] ([Id])
GO
ALTER TABLE [dbo].[EventInstanceJobTaskMappings] CHECK CONSTRAINT [EEventInstanceJobTaskMapping_JobTaskConfig]
GO
