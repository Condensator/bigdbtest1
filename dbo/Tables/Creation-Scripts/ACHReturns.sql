SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ACHReturns](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[FileLocation] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ACHReturnFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[ACHReturnFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[ACHReturnFile_Content] [varbinary](82) NOT NULL,
	[ACHRunId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ACHReturns]  WITH CHECK ADD  CONSTRAINT [EACHReturn_ACHRun] FOREIGN KEY([ACHRunId])
REFERENCES [dbo].[ACHRuns] ([Id])
GO
ALTER TABLE [dbo].[ACHReturns] CHECK CONSTRAINT [EACHReturn_ACHRun]
GO
ALTER TABLE [dbo].[ACHReturns]  WITH CHECK ADD  CONSTRAINT [EACHReturn_JobStepInstance] FOREIGN KEY([JobStepInstanceId])
REFERENCES [dbo].[JobStepInstances] ([Id])
GO
ALTER TABLE [dbo].[ACHReturns] CHECK CONSTRAINT [EACHReturn_JobStepInstance]
GO
