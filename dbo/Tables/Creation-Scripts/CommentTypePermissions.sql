SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommentTypePermissions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Condition] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AssignmentType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[Permission] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreationAllowed] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserSelectionId] [bigint] NOT NULL,
	[CommentTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommentTypePermissions]  WITH CHECK ADD  CONSTRAINT [ECommentType_CommentTypePermissions] FOREIGN KEY([CommentTypeId])
REFERENCES [dbo].[CommentTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommentTypePermissions] CHECK CONSTRAINT [ECommentType_CommentTypePermissions]
GO
ALTER TABLE [dbo].[CommentTypePermissions]  WITH CHECK ADD  CONSTRAINT [ECommentTypePermission_UserSelection] FOREIGN KEY([UserSelectionId])
REFERENCES [dbo].[UserSelectionParams] ([Id])
GO
ALTER TABLE [dbo].[CommentTypePermissions] CHECK CONSTRAINT [ECommentTypePermission_UserSelection]
GO
