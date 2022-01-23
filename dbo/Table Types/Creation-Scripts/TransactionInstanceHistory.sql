CREATE TYPE [dbo].[TransactionInstanceHistory] AS TABLE(
	[TransactionInstanceId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LatestWorkItemHistoryId] [bigint] NULL,
	[Reason] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[AsOfDate] [datetimeoffset](7) NOT NULL,
	[SuspendResumeComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[FollowUpDate] [date] NULL,
	[UserId] [bigint] NOT NULL,
	[SuspendReasonId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
