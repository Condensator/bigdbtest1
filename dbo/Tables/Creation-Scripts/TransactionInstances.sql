SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TransactionInstances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[TransactionName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[WorkflowSource] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EntitySummary] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[WorkflowInstanceId] [uniqueidentifier] NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[WorkflowInstanceData] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[FallbackForm] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[FollowUpDate] [date] NULL,
	[IsSuspendable] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsFromAutoAction] [bit] NOT NULL,
	[AccessScope] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AccessScopeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
