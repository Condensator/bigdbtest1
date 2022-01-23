SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommentLists](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RelatedAutomatically] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CommentId] [bigint] NOT NULL,
	[CommentHeaderId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsRootEntity] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommentLists]  WITH CHECK ADD  CONSTRAINT [ECommentHeader_CommentLists] FOREIGN KEY([CommentHeaderId])
REFERENCES [dbo].[CommentHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommentLists] CHECK CONSTRAINT [ECommentHeader_CommentLists]
GO
ALTER TABLE [dbo].[CommentLists]  WITH CHECK ADD  CONSTRAINT [ECommentList_Comment] FOREIGN KEY([CommentId])
REFERENCES [dbo].[Comments] ([Id])
GO
ALTER TABLE [dbo].[CommentLists] CHECK CONSTRAINT [ECommentList_Comment]
GO
