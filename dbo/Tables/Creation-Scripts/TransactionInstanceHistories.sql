SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TransactionInstanceHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TransactionInstanceId] [bigint] NOT NULL,
	[LatestWorkItemHistoryId] [bigint] NULL,
	[Reason] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[AsOfDate] [datetimeoffset](7) NOT NULL,
	[SuspendResumeComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[FollowUpDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[SuspendReasonId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TransactionInstanceHistories]  WITH CHECK ADD  CONSTRAINT [ETransactionInstanceHistory_SuspendReason] FOREIGN KEY([SuspendReasonId])
REFERENCES [dbo].[SuspendReasonConfigs] ([Id])
GO
ALTER TABLE [dbo].[TransactionInstanceHistories] CHECK CONSTRAINT [ETransactionInstanceHistory_SuspendReason]
GO
ALTER TABLE [dbo].[TransactionInstanceHistories]  WITH CHECK ADD  CONSTRAINT [ETransactionInstanceHistory_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[TransactionInstanceHistories] CHECK CONSTRAINT [ETransactionInstanceHistory_User]
GO
