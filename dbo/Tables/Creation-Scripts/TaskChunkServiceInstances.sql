SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaskChunkServiceInstances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Status] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[JobServiceId] [bigint] NOT NULL,
	[TaskChunkInstanceId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[TaskChunkServiceInstances]  WITH CHECK ADD  CONSTRAINT [ETaskChunkInstance_TaskChunkServiceInstances] FOREIGN KEY([TaskChunkInstanceId])
REFERENCES [dbo].[TaskChunkInstances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TaskChunkServiceInstances] CHECK CONSTRAINT [ETaskChunkInstance_TaskChunkServiceInstances]
GO
ALTER TABLE [dbo].[TaskChunkServiceInstances]  WITH CHECK ADD  CONSTRAINT [ETaskChunkServiceInstance_JobService] FOREIGN KEY([JobServiceId])
REFERENCES [dbo].[JobServices] ([Id])
GO
ALTER TABLE [dbo].[TaskChunkServiceInstances] CHECK CONSTRAINT [ETaskChunkServiceInstance_JobService]
GO
