SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentLists](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[GenerationOrder] [bigint] NOT NULL,
	[IsMandatory] [bit] NOT NULL,
	[ForceRegenerate] [bit] NOT NULL,
	[IsManual] [bit] NOT NULL,
	[AttachmentRequired] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DocumentId] [bigint] NULL,
	[DocumentGroupDetailId] [bigint] NULL,
	[DocumentTypeId] [bigint] NOT NULL,
	[DocumentHeaderId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[SpecificEntityId] [bigint] NULL,
	[SpecificEntityNaturalId] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[DocumentSource] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[EntityId] [bigint] NULL,
	[EnabledForESignature] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentLists]  WITH CHECK ADD  CONSTRAINT [EDocumentHeader_DocumentLists] FOREIGN KEY([DocumentHeaderId])
REFERENCES [dbo].[DocumentHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentLists] CHECK CONSTRAINT [EDocumentHeader_DocumentLists]
GO
ALTER TABLE [dbo].[DocumentLists]  WITH CHECK ADD  CONSTRAINT [EDocumentList_Document] FOREIGN KEY([DocumentId])
REFERENCES [dbo].[DocumentInstances] ([Id])
GO
ALTER TABLE [dbo].[DocumentLists] CHECK CONSTRAINT [EDocumentList_Document]
GO
ALTER TABLE [dbo].[DocumentLists]  WITH CHECK ADD  CONSTRAINT [EDocumentList_DocumentGroupDetail] FOREIGN KEY([DocumentGroupDetailId])
REFERENCES [dbo].[DocumentGroupDetails] ([Id])
GO
ALTER TABLE [dbo].[DocumentLists] CHECK CONSTRAINT [EDocumentList_DocumentGroupDetail]
GO
ALTER TABLE [dbo].[DocumentLists]  WITH CHECK ADD  CONSTRAINT [EDocumentList_DocumentType] FOREIGN KEY([DocumentTypeId])
REFERENCES [dbo].[DocumentTypes] ([Id])
GO
ALTER TABLE [dbo].[DocumentLists] CHECK CONSTRAINT [EDocumentList_DocumentType]
GO
