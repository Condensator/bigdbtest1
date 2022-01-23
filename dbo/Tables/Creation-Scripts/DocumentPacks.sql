SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentPacks](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[StatusDate] [date] NOT NULL,
	[CreatedDate] [date] NOT NULL,
	[Comment] [nvarchar](4000) COLLATE Latin1_General_CI_AS NULL,
	[EmailRowNumber] [int] NULL,
	[EmailSentTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PackedFromId] [bigint] NOT NULL,
	[StatusId] [bigint] NOT NULL,
	[PackedById] [bigint] NOT NULL,
	[StatusChangedById] [bigint] NOT NULL,
	[EmailSentById] [bigint] NULL,
	[DocumentHeaderId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AttachmentId] [bigint] NULL,
	[EnabledForESignature] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentPacks]  WITH CHECK ADD  CONSTRAINT [EDocumentHeader_DocumentPacks] FOREIGN KEY([DocumentHeaderId])
REFERENCES [dbo].[DocumentHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentPacks] CHECK CONSTRAINT [EDocumentHeader_DocumentPacks]
GO
ALTER TABLE [dbo].[DocumentPacks]  WITH CHECK ADD  CONSTRAINT [EDocumentPack_Attachment] FOREIGN KEY([AttachmentId])
REFERENCES [dbo].[AttachmentForDocs] ([Id])
GO
ALTER TABLE [dbo].[DocumentPacks] CHECK CONSTRAINT [EDocumentPack_Attachment]
GO
ALTER TABLE [dbo].[DocumentPacks]  WITH CHECK ADD  CONSTRAINT [EDocumentPack_EmailSentBy] FOREIGN KEY([EmailSentById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[DocumentPacks] CHECK CONSTRAINT [EDocumentPack_EmailSentBy]
GO
ALTER TABLE [dbo].[DocumentPacks]  WITH CHECK ADD  CONSTRAINT [EDocumentPack_PackedBy] FOREIGN KEY([PackedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[DocumentPacks] CHECK CONSTRAINT [EDocumentPack_PackedBy]
GO
ALTER TABLE [dbo].[DocumentPacks]  WITH CHECK ADD  CONSTRAINT [EDocumentPack_PackedFrom] FOREIGN KEY([PackedFromId])
REFERENCES [dbo].[SubSystemConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentPacks] CHECK CONSTRAINT [EDocumentPack_PackedFrom]
GO
ALTER TABLE [dbo].[DocumentPacks]  WITH CHECK ADD  CONSTRAINT [EDocumentPack_Status] FOREIGN KEY([StatusId])
REFERENCES [dbo].[DocumentStatusConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentPacks] CHECK CONSTRAINT [EDocumentPack_Status]
GO
ALTER TABLE [dbo].[DocumentPacks]  WITH CHECK ADD  CONSTRAINT [EDocumentPack_StatusChangedBy] FOREIGN KEY([StatusChangedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[DocumentPacks] CHECK CONSTRAINT [EDocumentPack_StatusChangedBy]
GO
