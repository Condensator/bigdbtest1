CREATE TYPE [dbo].[CommentUserPreference] AS TABLE(
	[IsFollowing] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsRead] [bit] NOT NULL,
	[Hidden] [bit] NOT NULL,
	[LastReadCommentResponseId] [bigint] NULL,
	[UserId] [bigint] NOT NULL,
	[CommentId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
