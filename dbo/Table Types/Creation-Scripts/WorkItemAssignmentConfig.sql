CREATE TYPE [dbo].[WorkItemAssignmentConfig] AS TABLE(
	[Condition] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssignmentType] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[UserExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[UserGroupExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[SequenceNumber] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsMultipleUser] [bit] NOT NULL,
	[SpecificWorkItemId] [bigint] NULL,
	[UserId] [bigint] NULL,
	[UserGroupId] [bigint] NULL,
	[WorkItemConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
