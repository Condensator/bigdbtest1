SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommentAttachments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CommentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AttachmentId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommentAttachments]  WITH CHECK ADD  CONSTRAINT [EComment_CommentAttachments] FOREIGN KEY([CommentId])
REFERENCES [dbo].[Comments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommentAttachments] CHECK CONSTRAINT [EComment_CommentAttachments]
GO
ALTER TABLE [dbo].[CommentAttachments]  WITH CHECK ADD  CONSTRAINT [ECommentAttachment_Attachment] FOREIGN KEY([AttachmentId])
REFERENCES [dbo].[Attachments] ([Id])
GO
ALTER TABLE [dbo].[CommentAttachments] CHECK CONSTRAINT [ECommentAttachment_Attachment]
GO
