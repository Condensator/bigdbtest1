SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentEmailAttachments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DocumentAttachmentId] [bigint] NULL,
	[DocumentPackAttachmentId] [bigint] NULL,
	[DocumentEmailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentEmailAttachments]  WITH CHECK ADD  CONSTRAINT [EDocumentEmail_DocumentEmailAttachments] FOREIGN KEY([DocumentEmailId])
REFERENCES [dbo].[DocumentEmails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentEmailAttachments] CHECK CONSTRAINT [EDocumentEmail_DocumentEmailAttachments]
GO
ALTER TABLE [dbo].[DocumentEmailAttachments]  WITH CHECK ADD  CONSTRAINT [EDocumentEmailAttachment_DocumentAttachment] FOREIGN KEY([DocumentAttachmentId])
REFERENCES [dbo].[DocumentAttachments] ([Id])
GO
ALTER TABLE [dbo].[DocumentEmailAttachments] CHECK CONSTRAINT [EDocumentEmailAttachment_DocumentAttachment]
GO
ALTER TABLE [dbo].[DocumentEmailAttachments]  WITH CHECK ADD  CONSTRAINT [EDocumentEmailAttachment_DocumentPackAttachment] FOREIGN KEY([DocumentPackAttachmentId])
REFERENCES [dbo].[DocumentPackAttachments] ([Id])
GO
ALTER TABLE [dbo].[DocumentEmailAttachments] CHECK CONSTRAINT [EDocumentEmailAttachment_DocumentPackAttachment]
GO
