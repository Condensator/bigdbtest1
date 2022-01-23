CREATE TYPE [dbo].[CommentEntityTag] AS TABLE(
	[EntityId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RelateAutomatically] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsChanged] [bit] NOT NULL,
	[CommentListId] [bigint] NULL,
	[Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsRootEntity] [bit] NOT NULL,
	[EntityTypeId] [bigint] NOT NULL,
	[CommentId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
