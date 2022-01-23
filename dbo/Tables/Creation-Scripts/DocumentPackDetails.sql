SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentPackDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AttachmentId] [bigint] NOT NULL,
	[DocumentPackId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentPackDetails]  WITH CHECK ADD  CONSTRAINT [EDocumentPack_DocumentPackDetails] FOREIGN KEY([DocumentPackId])
REFERENCES [dbo].[DocumentPacks] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentPackDetails] CHECK CONSTRAINT [EDocumentPack_DocumentPackDetails]
GO
ALTER TABLE [dbo].[DocumentPackDetails]  WITH CHECK ADD  CONSTRAINT [EDocumentPackDetail_Attachment] FOREIGN KEY([AttachmentId])
REFERENCES [dbo].[DocumentAttachments] ([Id])
GO
ALTER TABLE [dbo].[DocumentPackDetails] CHECK CONSTRAINT [EDocumentPackDetail_Attachment]
GO
