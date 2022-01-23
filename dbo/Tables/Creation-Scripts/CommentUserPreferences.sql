SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommentUserPreferences](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsFollowing] [bit] NOT NULL,
	[IsRead] [bit] NOT NULL,
	[Hidden] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NOT NULL,
	[CommentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LastReadCommentResponseId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommentUserPreferences]  WITH CHECK ADD  CONSTRAINT [EComment_CommentUserPreferences] FOREIGN KEY([CommentId])
REFERENCES [dbo].[Comments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommentUserPreferences] CHECK CONSTRAINT [EComment_CommentUserPreferences]
GO
ALTER TABLE [dbo].[CommentUserPreferences]  WITH CHECK ADD  CONSTRAINT [ECommentUserPreference_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[CommentUserPreferences] CHECK CONSTRAINT [ECommentUserPreference_User]
GO
