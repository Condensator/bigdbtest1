SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommentPermissions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Permission] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NOT NULL,
	[CommentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsAddedManually] [bit] NOT NULL,
	[CommentTypePermissionId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommentPermissions]  WITH CHECK ADD  CONSTRAINT [EComment_CommentPermissions] FOREIGN KEY([CommentId])
REFERENCES [dbo].[Comments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommentPermissions] CHECK CONSTRAINT [EComment_CommentPermissions]
GO
ALTER TABLE [dbo].[CommentPermissions]  WITH CHECK ADD  CONSTRAINT [ECommentPermission_CommentTypePermission] FOREIGN KEY([CommentTypePermissionId])
REFERENCES [dbo].[CommentTypePermissions] ([Id])
GO
ALTER TABLE [dbo].[CommentPermissions] CHECK CONSTRAINT [ECommentPermission_CommentTypePermission]
GO
ALTER TABLE [dbo].[CommentPermissions]  WITH CHECK ADD  CONSTRAINT [ECommentPermission_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[CommentPermissions] CHECK CONSTRAINT [ECommentPermission_User]
GO
