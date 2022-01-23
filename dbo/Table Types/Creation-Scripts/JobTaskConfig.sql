CREATE TYPE [dbo].[JobTaskConfig] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserFriendlyName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsParallel] [bit] NOT NULL,
	[IsSystemJob] [bit] NOT NULL,
	[IsCancellable] [bit] NOT NULL,
	[PageSize] [int] NOT NULL,
	[IsExternalCall] [bit] NOT NULL,
	[ChunkServiceLimit] [int] NULL,
	[ChunkSize] [int] NULL,
	[RetryFaultedBackgroundEventsBeforeRun] [bit] NOT NULL,
	[WaitForBackgroundEventsCompletionAfterRun] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
