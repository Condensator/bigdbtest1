SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AutoActionTemplateComments](
	[Id] [bigint] NOT NULL,
	[Title] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[AlertComment] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ConversationMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[Body] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CommentTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AuthorId] [bigint] NULL,
	[AuthorExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsInternal] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AutoActionTemplateComments]  WITH CHECK ADD  CONSTRAINT [EAutoActionTemplate_AutoActionTemplateComment] FOREIGN KEY([Id])
REFERENCES [dbo].[AutoActionTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AutoActionTemplateComments] CHECK CONSTRAINT [EAutoActionTemplate_AutoActionTemplateComment]
GO
ALTER TABLE [dbo].[AutoActionTemplateComments]  WITH CHECK ADD  CONSTRAINT [EAutoActionTemplateComment_Author] FOREIGN KEY([AuthorId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[AutoActionTemplateComments] CHECK CONSTRAINT [EAutoActionTemplateComment_Author]
GO
ALTER TABLE [dbo].[AutoActionTemplateComments]  WITH CHECK ADD  CONSTRAINT [EAutoActionTemplateComment_CommentType] FOREIGN KEY([CommentTypeId])
REFERENCES [dbo].[CommentTypes] ([Id])
GO
ALTER TABLE [dbo].[AutoActionTemplateComments] CHECK CONSTRAINT [EAutoActionTemplateComment_CommentType]
GO
