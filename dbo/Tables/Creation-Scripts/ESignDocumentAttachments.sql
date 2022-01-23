SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ESignDocumentAttachments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsPacket] [bit] NOT NULL,
	[AttachmentId] [bigint] NOT NULL,
	[ESignEnvelopeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DocumentAttachmentId] [bigint] NULL,
	[DocumentPackAttachmentId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ESignDocumentAttachments]  WITH CHECK ADD  CONSTRAINT [EESignDocumentAttachment_Attachment] FOREIGN KEY([AttachmentId])
REFERENCES [dbo].[AttachmentForDocs] ([Id])
GO
ALTER TABLE [dbo].[ESignDocumentAttachments] CHECK CONSTRAINT [EESignDocumentAttachment_Attachment]
GO
ALTER TABLE [dbo].[ESignDocumentAttachments]  WITH CHECK ADD  CONSTRAINT [EESignDocumentAttachment_DocumentAttachment] FOREIGN KEY([DocumentAttachmentId])
REFERENCES [dbo].[DocumentAttachments] ([Id])
GO
ALTER TABLE [dbo].[ESignDocumentAttachments] CHECK CONSTRAINT [EESignDocumentAttachment_DocumentAttachment]
GO
ALTER TABLE [dbo].[ESignDocumentAttachments]  WITH CHECK ADD  CONSTRAINT [EESignDocumentAttachment_DocumentPackAttachment] FOREIGN KEY([DocumentPackAttachmentId])
REFERENCES [dbo].[DocumentPackAttachments] ([Id])
GO
ALTER TABLE [dbo].[ESignDocumentAttachments] CHECK CONSTRAINT [EESignDocumentAttachment_DocumentPackAttachment]
GO
ALTER TABLE [dbo].[ESignDocumentAttachments]  WITH CHECK ADD  CONSTRAINT [EESignEnvelope_ESignDocumentAttachments] FOREIGN KEY([ESignEnvelopeId])
REFERENCES [dbo].[ESignEnvelopes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ESignDocumentAttachments] CHECK CONSTRAINT [EESignEnvelope_ESignDocumentAttachments]
GO
