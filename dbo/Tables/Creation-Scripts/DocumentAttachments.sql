SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentAttachments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RowNumber] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AttachmentId] [bigint] NOT NULL,
	[DocumentInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsModificationRequired] [bit] NOT NULL,
	[ModificationComment] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ModificationReason] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentAttachments]  WITH CHECK ADD  CONSTRAINT [EDocumentAttachment_Attachment] FOREIGN KEY([AttachmentId])
REFERENCES [dbo].[AttachmentForDocs] ([Id])
GO
ALTER TABLE [dbo].[DocumentAttachments] CHECK CONSTRAINT [EDocumentAttachment_Attachment]
GO
ALTER TABLE [dbo].[DocumentAttachments]  WITH CHECK ADD  CONSTRAINT [EDocumentInstance_DocumentAttachments] FOREIGN KEY([DocumentInstanceId])
REFERENCES [dbo].[DocumentInstances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentAttachments] CHECK CONSTRAINT [EDocumentInstance_DocumentAttachments]
GO
