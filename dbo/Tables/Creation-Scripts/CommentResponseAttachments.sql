SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommentResponseAttachments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AttachmentId] [bigint] NOT NULL,
	[CommentResponseId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommentResponseAttachments]  WITH CHECK ADD  CONSTRAINT [ECommentResponse_CommentResponseAttachments] FOREIGN KEY([CommentResponseId])
REFERENCES [dbo].[CommentResponses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommentResponseAttachments] CHECK CONSTRAINT [ECommentResponse_CommentResponseAttachments]
GO
ALTER TABLE [dbo].[CommentResponseAttachments]  WITH CHECK ADD  CONSTRAINT [ECommentResponseAttachment_Attachment] FOREIGN KEY([AttachmentId])
REFERENCES [dbo].[Attachments] ([Id])
GO
ALTER TABLE [dbo].[CommentResponseAttachments] CHECK CONSTRAINT [ECommentResponseAttachment_Attachment]
GO
