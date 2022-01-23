SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JobStepInstances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[StartDate] [datetimeoffset](7) NULL,
	[EndDate] [datetimeoffset](7) NULL,
	[Status] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Attachment_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[Attachment_Content] [varbinary](82) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobStepId] [bigint] NOT NULL,
	[JobInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[JobServiceId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[JobStepInstances]  WITH CHECK ADD  CONSTRAINT [EJobInstance_JobStepInstances] FOREIGN KEY([JobInstanceId])
REFERENCES [dbo].[JobInstances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[JobStepInstances] CHECK CONSTRAINT [EJobInstance_JobStepInstances]
GO
ALTER TABLE [dbo].[JobStepInstances]  WITH CHECK ADD  CONSTRAINT [EJobStepInstance_JobService] FOREIGN KEY([JobServiceId])
REFERENCES [dbo].[JobServices] ([Id])
GO
ALTER TABLE [dbo].[JobStepInstances] CHECK CONSTRAINT [EJobStepInstance_JobService]
GO
ALTER TABLE [dbo].[JobStepInstances]  WITH CHECK ADD  CONSTRAINT [EJobStepInstance_JobStep] FOREIGN KEY([JobStepId])
REFERENCES [dbo].[JobSteps] ([Id])
GO
ALTER TABLE [dbo].[JobStepInstances] CHECK CONSTRAINT [EJobStepInstance_JobStep]
GO
