SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Attachments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[File_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[File_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[File_Content] [varbinary](82) NOT NULL,
	[Description] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[AttachedDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AttachedById] [bigint] NOT NULL,
	[SourceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Attachments]  WITH CHECK ADD  CONSTRAINT [EAttachment_AttachedBy] FOREIGN KEY([AttachedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Attachments] CHECK CONSTRAINT [EAttachment_AttachedBy]
GO
ALTER TABLE [dbo].[Attachments]  WITH CHECK ADD  CONSTRAINT [EAttachment_Source] FOREIGN KEY([SourceId])
REFERENCES [dbo].[SubSystemConfigs] ([Id])
GO
ALTER TABLE [dbo].[Attachments] CHECK CONSTRAINT [EAttachment_Source]
GO
