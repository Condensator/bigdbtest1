SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Comments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Body] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Importance] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ConversationMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[OriginalCreatedTime] [datetimeoffset](7) NOT NULL,
	[FollowUpDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CommentTypeId] [bigint] NOT NULL,
	[AuthorId] [bigint] NOT NULL,
	[FollowUpById] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DefaultPermission] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityId] [bigint] NULL,
	[EntityTypeId] [bigint] NULL,
	[IsInternal] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Comments]  WITH CHECK ADD  CONSTRAINT [EComment_Author] FOREIGN KEY([AuthorId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Comments] CHECK CONSTRAINT [EComment_Author]
GO
ALTER TABLE [dbo].[Comments]  WITH CHECK ADD  CONSTRAINT [EComment_CommentType] FOREIGN KEY([CommentTypeId])
REFERENCES [dbo].[CommentTypes] ([Id])
GO
ALTER TABLE [dbo].[Comments] CHECK CONSTRAINT [EComment_CommentType]
GO
ALTER TABLE [dbo].[Comments]  WITH CHECK ADD  CONSTRAINT [EComment_EntityType] FOREIGN KEY([EntityTypeId])
REFERENCES [dbo].[CommentEntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[Comments] CHECK CONSTRAINT [EComment_EntityType]
GO
ALTER TABLE [dbo].[Comments]  WITH CHECK ADD  CONSTRAINT [EComment_FollowUpBy] FOREIGN KEY([FollowUpById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Comments] CHECK CONSTRAINT [EComment_FollowUpBy]
GO
