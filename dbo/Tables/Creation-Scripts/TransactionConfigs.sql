SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TransactionConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntitySummaryExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsNotify] [bit] NOT NULL,
	[IsSuspendable] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Mode] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrimaryEntity] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsVisibleInUI] [bit] NOT NULL,
	[WorkflowSource] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsCurrent] [bit] NOT NULL,
	[AllowSubscription] [bit] NOT NULL,
	[AllowWorkItemAssignment] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
