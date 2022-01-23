SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EnmasseMeterReadingHistoryLogs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EnmasseMeterReadingHistoryId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[EnmasseMeterReadingHistoryLogs]  WITH CHECK ADD  CONSTRAINT [EEnmasseMeterReadingHistory_EnmasseMeterReadingHistoryLogs] FOREIGN KEY([EnmasseMeterReadingHistoryId])
REFERENCES [dbo].[EnmasseMeterReadingHistories] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EnmasseMeterReadingHistoryLogs] CHECK CONSTRAINT [EEnmasseMeterReadingHistory_EnmasseMeterReadingHistoryLogs]
GO
