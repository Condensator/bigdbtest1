SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommentTags](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CommentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TagId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommentTags]  WITH CHECK ADD  CONSTRAINT [EComment_CommentTags] FOREIGN KEY([CommentId])
REFERENCES [dbo].[Comments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommentTags] CHECK CONSTRAINT [EComment_CommentTags]
GO
ALTER TABLE [dbo].[CommentTags]  WITH CHECK ADD  CONSTRAINT [ECommentTag_Tag] FOREIGN KEY([TagId])
REFERENCES [dbo].[CommentTagValuesConfigs] ([Id])
GO
ALTER TABLE [dbo].[CommentTags] CHECK CONSTRAINT [ECommentTag_Tag]
GO
