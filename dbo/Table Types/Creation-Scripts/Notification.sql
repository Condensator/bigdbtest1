CREATE TYPE [dbo].[Notification] AS TABLE(
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AsOfDate] [datetimeoffset](7) NULL,
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EntityId] [bigint] NULL,
	[TransactionInstanceId] [bigint] NULL,
	[WorkItemId] [bigint] NULL,
	[SourceModule] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[SourceId] [bigint] NULL,
	[EvaluateContentAtRuntime] [bit] NOT NULL,
	[NotificationRecipientConfigId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
