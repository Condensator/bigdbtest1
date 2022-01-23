SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommentEntityTags](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[RelateAutomatically] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsRootEntity] [bit] NOT NULL,
	[IsChanged] [bit] NOT NULL,
	[CommentListId] [bigint] NULL,
	[Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityTypeId] [bigint] NOT NULL,
	[CommentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommentEntityTags]  WITH CHECK ADD  CONSTRAINT [EComment_CommentEntityTags] FOREIGN KEY([CommentId])
REFERENCES [dbo].[Comments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommentEntityTags] CHECK CONSTRAINT [EComment_CommentEntityTags]
GO
ALTER TABLE [dbo].[CommentEntityTags]  WITH CHECK ADD  CONSTRAINT [ECommentEntityTag_EntityType] FOREIGN KEY([EntityTypeId])
REFERENCES [dbo].[EntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[CommentEntityTags] CHECK CONSTRAINT [ECommentEntityTag_EntityType]
GO
