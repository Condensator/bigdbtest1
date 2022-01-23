SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommentTypeSubSystemDetails](
	[Viewable] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SubSystemId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CommentTypeId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommentTypeSubSystemDetails]  WITH CHECK ADD  CONSTRAINT [ECommentType_CommentTypeSubSystemDetails] FOREIGN KEY([CommentTypeId])
REFERENCES [dbo].[CommentTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommentTypeSubSystemDetails] CHECK CONSTRAINT [ECommentType_CommentTypeSubSystemDetails]
GO
ALTER TABLE [dbo].[CommentTypeSubSystemDetails]  WITH CHECK ADD  CONSTRAINT [ECommentTypeSubSystemDetail_SubSystem] FOREIGN KEY([SubSystemId])
REFERENCES [dbo].[SubSystemConfigs] ([Id])
GO
ALTER TABLE [dbo].[CommentTypeSubSystemDetails] CHECK CONSTRAINT [ECommentTypeSubSystemDetail_SubSystem]
GO
