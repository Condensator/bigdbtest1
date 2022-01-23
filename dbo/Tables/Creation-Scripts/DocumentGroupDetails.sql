SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentGroupDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsMandatory] [bit] NOT NULL,
	[ForceRegenerate] [bit] NOT NULL,
	[AttachmentRequired] [bit] NOT NULL,
	[DefaultTemplateExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DocumentTypeId] [bigint] NOT NULL,
	[DefaultTemplateId] [bigint] NULL,
	[DocumentGroupId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AutoGenerate] [bit] NOT NULL,
	[GenerationOrder] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentGroupDetails]  WITH CHECK ADD  CONSTRAINT [EDocumentGroup_DocumentGroupDetails] FOREIGN KEY([DocumentGroupId])
REFERENCES [dbo].[DocumentGroups] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentGroupDetails] CHECK CONSTRAINT [EDocumentGroup_DocumentGroupDetails]
GO
ALTER TABLE [dbo].[DocumentGroupDetails]  WITH CHECK ADD  CONSTRAINT [EDocumentGroupDetail_DefaultTemplate] FOREIGN KEY([DefaultTemplateId])
REFERENCES [dbo].[DocumentTemplates] ([Id])
GO
ALTER TABLE [dbo].[DocumentGroupDetails] CHECK CONSTRAINT [EDocumentGroupDetail_DefaultTemplate]
GO
ALTER TABLE [dbo].[DocumentGroupDetails]  WITH CHECK ADD  CONSTRAINT [EDocumentGroupDetail_DocumentType] FOREIGN KEY([DocumentTypeId])
REFERENCES [dbo].[DocumentTypes] ([Id])
GO
ALTER TABLE [dbo].[DocumentGroupDetails] CHECK CONSTRAINT [EDocumentGroupDetail_DocumentType]
GO
