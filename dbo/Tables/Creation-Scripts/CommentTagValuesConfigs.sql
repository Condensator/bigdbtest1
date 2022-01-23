SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommentTagValuesConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Value] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CommentTagConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommentTagValuesConfigs]  WITH CHECK ADD  CONSTRAINT [ECommentTagConfig_CommentTagValuesConfigs] FOREIGN KEY([CommentTagConfigId])
REFERENCES [dbo].[CommentTagConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommentTagValuesConfigs] CHECK CONSTRAINT [ECommentTagConfig_CommentTagValuesConfigs]
GO
