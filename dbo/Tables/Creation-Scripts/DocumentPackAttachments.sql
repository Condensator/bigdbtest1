SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentPackAttachments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AttachmentId] [bigint] NOT NULL,
	[DocumentPackId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentPackAttachments]  WITH CHECK ADD  CONSTRAINT [EDocumentPack_DocumentPackAttachments] FOREIGN KEY([DocumentPackId])
REFERENCES [dbo].[DocumentPacks] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentPackAttachments] CHECK CONSTRAINT [EDocumentPack_DocumentPackAttachments]
GO
ALTER TABLE [dbo].[DocumentPackAttachments]  WITH CHECK ADD  CONSTRAINT [EDocumentPackAttachment_Attachment] FOREIGN KEY([AttachmentId])
REFERENCES [dbo].[AttachmentForDocs] ([Id])
GO
ALTER TABLE [dbo].[DocumentPackAttachments] CHECK CONSTRAINT [EDocumentPackAttachment_Attachment]
GO
