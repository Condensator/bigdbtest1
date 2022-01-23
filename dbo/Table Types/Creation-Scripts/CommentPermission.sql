CREATE TYPE [dbo].[CommentPermission] AS TABLE(
	[Permission] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[IsAddedManually] [bit] NOT NULL,
	[UserId] [bigint] NOT NULL,
	[CommentTypePermissionId] [bigint] NULL,
	[CommentId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
