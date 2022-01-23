SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JobServiceDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[StartTime] [datetimeoffset](7) NOT NULL,
	[StopTime] [datetimeoffset](7) NULL,
	[JobServiceId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[JobServiceDetails]  WITH CHECK ADD  CONSTRAINT [EJobService_JobServiceDetails] FOREIGN KEY([JobServiceId])
REFERENCES [dbo].[JobServices] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[JobServiceDetails] CHECK CONSTRAINT [EJobService_JobServiceDetails]
GO
