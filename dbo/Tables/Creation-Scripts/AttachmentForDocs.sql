SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AttachmentForDocs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeneratedRawFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[GeneratedRawFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[GeneratedRawFile_Content] [varbinary](82) NULL,
	[IsGenerated] [bit] NOT NULL,
	[IsPacked] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AttachmentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsSample] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AttachmentForDocs]  WITH CHECK ADD  CONSTRAINT [EAttachmentForDoc_Attachment] FOREIGN KEY([AttachmentId])
REFERENCES [dbo].[Attachments] ([Id])
GO
ALTER TABLE [dbo].[AttachmentForDocs] CHECK CONSTRAINT [EAttachmentForDoc_Attachment]
GO
