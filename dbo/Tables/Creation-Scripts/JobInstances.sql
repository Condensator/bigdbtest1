SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JobInstances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[StartDate] [datetimeoffset](7) NOT NULL,
	[EndDate] [datetimeoffset](7) NULL,
	[Status] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvocationReason] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[BusinessDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobId] [bigint] NOT NULL,
	[SourceJobInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[JobServiceId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[JobInstances]  WITH CHECK ADD  CONSTRAINT [EJobInstance_Job] FOREIGN KEY([JobId])
REFERENCES [dbo].[Jobs] ([Id])
GO
ALTER TABLE [dbo].[JobInstances] CHECK CONSTRAINT [EJobInstance_Job]
GO
ALTER TABLE [dbo].[JobInstances]  WITH CHECK ADD  CONSTRAINT [EJobInstance_JobService] FOREIGN KEY([JobServiceId])
REFERENCES [dbo].[JobServices] ([Id])
GO
ALTER TABLE [dbo].[JobInstances] CHECK CONSTRAINT [EJobInstance_JobService]
GO
ALTER TABLE [dbo].[JobInstances]  WITH CHECK ADD  CONSTRAINT [EJobInstance_SourceJobInstance] FOREIGN KEY([SourceJobInstanceId])
REFERENCES [dbo].[JobInstances] ([Id])
GO
ALTER TABLE [dbo].[JobInstances] CHECK CONSTRAINT [EJobInstance_SourceJobInstance]
GO
