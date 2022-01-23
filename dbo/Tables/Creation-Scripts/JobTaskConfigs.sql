SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JobTaskConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[UserFriendlyName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsParallel] [bit] NOT NULL,
	[IsSystemJob] [bit] NOT NULL,
	[IsCancellable] [bit] NOT NULL,
	[PageSize] [int] NOT NULL,
	[IsExternalCall] [bit] NOT NULL,
	[ChunkServiceLimit] [int] NULL,
	[ChunkSize] [int] NULL,
	[RetryFaultedBackgroundEventsBeforeRun] [bit] NOT NULL,
	[WaitForBackgroundEventsCompletionAfterRun] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
