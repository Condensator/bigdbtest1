SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EnmasseMeterReadingLogs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EnmasseMeterReadingInstanceId] [bigint] NOT NULL,
	[Error] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
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
ALTER TABLE [dbo].[EnmasseMeterReadingLogs]  WITH CHECK ADD  CONSTRAINT [EEnmasseMeterReadingInstance_EnmasseMeterReadingLogs] FOREIGN KEY([EnmasseMeterReadingInstanceId])
REFERENCES [dbo].[EnmasseMeterReadingInstances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EnmasseMeterReadingLogs] CHECK CONSTRAINT [EEnmasseMeterReadingInstance_EnmasseMeterReadingLogs]
GO