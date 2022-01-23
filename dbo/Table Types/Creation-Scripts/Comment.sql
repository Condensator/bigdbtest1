CREATE TYPE [dbo].[Comment] AS TABLE(
	[Title] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Body] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Importance] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsInternal] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ConversationMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[OriginalCreatedTime] [datetimeoffset](7) NOT NULL,
	[FollowUpDate] [date] NULL,
	[DefaultPermission] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityId] [bigint] NULL,
	[CommentTypeId] [bigint] NOT NULL,
	[AuthorId] [bigint] NOT NULL,
	[FollowUpById] [bigint] NULL,
	[EntityTypeId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
