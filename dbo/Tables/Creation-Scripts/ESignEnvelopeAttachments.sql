SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ESignEnvelopeAttachments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[DocumentAttachmentId] [bigint] NULL,
	[DocumentPackAttachmentId] [bigint] NULL,
	[ESignEnvelopeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CompletedAttachmentId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ESignEnvelopeAttachments]  WITH CHECK ADD  CONSTRAINT [EESignEnvelope_ESignEnvelopeAttachments] FOREIGN KEY([ESignEnvelopeId])
REFERENCES [dbo].[ESignEnvelopes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ESignEnvelopeAttachments] CHECK CONSTRAINT [EESignEnvelope_ESignEnvelopeAttachments]
GO
ALTER TABLE [dbo].[ESignEnvelopeAttachments]  WITH CHECK ADD  CONSTRAINT [EESignEnvelopeAttachment_CompletedAttachment] FOREIGN KEY([CompletedAttachmentId])
REFERENCES [dbo].[Attachments] ([Id])
GO
ALTER TABLE [dbo].[ESignEnvelopeAttachments] CHECK CONSTRAINT [EESignEnvelopeAttachment_CompletedAttachment]
GO
ALTER TABLE [dbo].[ESignEnvelopeAttachments]  WITH CHECK ADD  CONSTRAINT [EESignEnvelopeAttachment_DocumentAttachment] FOREIGN KEY([DocumentAttachmentId])
REFERENCES [dbo].[DocumentAttachments] ([Id])
GO
ALTER TABLE [dbo].[ESignEnvelopeAttachments] CHECK CONSTRAINT [EESignEnvelopeAttachment_DocumentAttachment]
GO
ALTER TABLE [dbo].[ESignEnvelopeAttachments]  WITH CHECK ADD  CONSTRAINT [EESignEnvelopeAttachment_DocumentPackAttachment] FOREIGN KEY([DocumentPackAttachmentId])
REFERENCES [dbo].[DocumentPackAttachments] ([Id])
GO
ALTER TABLE [dbo].[ESignEnvelopeAttachments] CHECK CONSTRAINT [EESignEnvelopeAttachment_DocumentPackAttachment]
GO
