CREATE TYPE [dbo].[AutoActionLogDetail] AS TABLE(
	[EntityId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsSuccess] [bit] NOT NULL,
	[WorkItemId] [bigint] NULL,
	[CommentId] [bigint] NULL,
	[AutoActionLogId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
