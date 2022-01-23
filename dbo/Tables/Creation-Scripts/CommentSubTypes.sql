SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommentSubTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CommentId] [bigint] NOT NULL,
	[CommentTypeSubTypeId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommentSubTypes]  WITH CHECK ADD  CONSTRAINT [EComment_CommentSubTypes] FOREIGN KEY([CommentId])
REFERENCES [dbo].[Comments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommentSubTypes] CHECK CONSTRAINT [EComment_CommentSubTypes]
GO
ALTER TABLE [dbo].[CommentSubTypes]  WITH CHECK ADD  CONSTRAINT [ECommentSubType_CommentTypeSubType] FOREIGN KEY([CommentTypeSubTypeId])
REFERENCES [dbo].[CommentTypeSubTypes] ([Id])
GO
ALTER TABLE [dbo].[CommentSubTypes] CHECK CONSTRAINT [ECommentSubType_CommentTypeSubType]
GO
