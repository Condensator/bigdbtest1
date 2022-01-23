CREATE TYPE [dbo].[UserSelectionParam] AS TABLE(
	[UserExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserGroupExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[UserId] [bigint] NULL,
	[UserGroupId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
