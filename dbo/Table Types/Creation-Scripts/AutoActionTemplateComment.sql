CREATE TYPE [dbo].[AutoActionTemplateComment] AS TABLE(
	[Title] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AlertComment] [bit] NOT NULL,
	[ConversationMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsInternal] [bit] NOT NULL,
	[Body] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[AuthorExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CommentTypeId] [bigint] NOT NULL,
	[AuthorId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
