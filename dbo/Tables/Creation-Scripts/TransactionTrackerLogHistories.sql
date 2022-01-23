SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TransactionTrackerLogHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TrackerKey] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[TrackerEntryToken] [nvarchar](4000) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LockedById] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[TransactionTrackerLogHistories]  WITH CHECK ADD  CONSTRAINT [ETransactionTrackerLogHistory_LockedBy] FOREIGN KEY([LockedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[TransactionTrackerLogHistories] CHECK CONSTRAINT [ETransactionTrackerLogHistory_LockedBy]
GO
