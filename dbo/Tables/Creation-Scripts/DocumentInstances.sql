SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentInstances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[EntityNaturalId] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Title] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EffectiveDate] [date] NULL,
	[ExpiryDate] [date] NULL,
	[IsModificationRequired] [bit] NOT NULL,
	[ModificationReason] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[ModificationComment] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ExceptionComment] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[IsGenerationAllowed] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsReadOnly] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DocumentTypeId] [bigint] NOT NULL,
	[DocumentTemplateId] [bigint] NULL,
	[DocumentTemplateDetailId] [bigint] NULL,
	[StatusId] [bigint] NOT NULL,
	[RelatedInstanceId] [bigint] NULL,
	[AttachmentDetailId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DefaultPermission] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsRetention] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentInstances]  WITH CHECK ADD  CONSTRAINT [EDocumentInstance_AttachmentDetail] FOREIGN KEY([AttachmentDetailId])
REFERENCES [dbo].[AttachmentForDocs] ([Id])
GO
ALTER TABLE [dbo].[DocumentInstances] CHECK CONSTRAINT [EDocumentInstance_AttachmentDetail]
GO
ALTER TABLE [dbo].[DocumentInstances]  WITH CHECK ADD  CONSTRAINT [EDocumentInstance_DocumentTemplate] FOREIGN KEY([DocumentTemplateId])
REFERENCES [dbo].[DocumentTemplates] ([Id])
GO
ALTER TABLE [dbo].[DocumentInstances] CHECK CONSTRAINT [EDocumentInstance_DocumentTemplate]
GO
ALTER TABLE [dbo].[DocumentInstances]  WITH CHECK ADD  CONSTRAINT [EDocumentInstance_DocumentTemplateDetail] FOREIGN KEY([DocumentTemplateDetailId])
REFERENCES [dbo].[DocumentTemplateDetails] ([Id])
GO
ALTER TABLE [dbo].[DocumentInstances] CHECK CONSTRAINT [EDocumentInstance_DocumentTemplateDetail]
GO
ALTER TABLE [dbo].[DocumentInstances]  WITH CHECK ADD  CONSTRAINT [EDocumentInstance_DocumentType] FOREIGN KEY([DocumentTypeId])
REFERENCES [dbo].[DocumentTypes] ([Id])
GO
ALTER TABLE [dbo].[DocumentInstances] CHECK CONSTRAINT [EDocumentInstance_DocumentType]
GO
ALTER TABLE [dbo].[DocumentInstances]  WITH CHECK ADD  CONSTRAINT [EDocumentInstance_RelatedInstance] FOREIGN KEY([RelatedInstanceId])
REFERENCES [dbo].[DocumentInstances] ([Id])
GO
ALTER TABLE [dbo].[DocumentInstances] CHECK CONSTRAINT [EDocumentInstance_RelatedInstance]
GO
ALTER TABLE [dbo].[DocumentInstances]  WITH CHECK ADD  CONSTRAINT [EDocumentInstance_Status] FOREIGN KEY([StatusId])
REFERENCES [dbo].[DocumentStatusConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentInstances] CHECK CONSTRAINT [EDocumentInstance_Status]
GO
