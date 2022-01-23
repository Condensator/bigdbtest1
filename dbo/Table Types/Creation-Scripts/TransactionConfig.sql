CREATE TYPE [dbo].[TransactionConfig] AS TABLE(
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Mode] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntitySummaryExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsNotify] [bit] NOT NULL,
	[IsSuspendable] [bit] NOT NULL,
	[PrimaryEntity] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsVisibleInUI] [bit] NOT NULL,
	[Description] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[WorkflowSource] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsCurrent] [bit] NOT NULL,
	[AllowSubscription] [bit] NOT NULL,
	[AllowWorkItemAssignment] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
