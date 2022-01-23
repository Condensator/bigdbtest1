SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JobSteps](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TaskParam] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ExecutionOrder] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[OnHold] [bit] NOT NULL,
	[RunOnHoliday] [bit] NOT NULL,
	[AbortOnFailure] [bit] NOT NULL,
	[ReRun] [bit] NOT NULL,
	[LatestInstanceStatus] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaskId] [bigint] NOT NULL,
	[EmailAttachment] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[JobSteps]  WITH CHECK ADD  CONSTRAINT [EJob_JobSteps] FOREIGN KEY([JobId])
REFERENCES [dbo].[Jobs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[JobSteps] CHECK CONSTRAINT [EJob_JobSteps]
GO
ALTER TABLE [dbo].[JobSteps]  WITH CHECK ADD  CONSTRAINT [EJobStep_Task] FOREIGN KEY([TaskId])
REFERENCES [dbo].[JobTaskConfigs] ([Id])
GO
ALTER TABLE [dbo].[JobSteps] CHECK CONSTRAINT [EJobStep_Task]
GO
