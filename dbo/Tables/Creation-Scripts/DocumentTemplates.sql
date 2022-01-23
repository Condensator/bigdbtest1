SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentTemplates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsLanguageApplicable] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ScriptId] [bigint] NULL,
	[DocumentTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[RelatedEntityId] [bigint] NULL,
	[GeneratedTemplate_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[GeneratedTemplate_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[GeneratedTemplate_Content] [varbinary](82) NULL,
	[IsExpressionBased] [bit] NOT NULL,
	[EnabledForESignature] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentTemplates]  WITH CHECK ADD  CONSTRAINT [EDocumentTemplate_Script] FOREIGN KEY([ScriptId])
REFERENCES [dbo].[DocumentExtractionScripts] ([Id])
GO
ALTER TABLE [dbo].[DocumentTemplates] CHECK CONSTRAINT [EDocumentTemplate_Script]
GO
ALTER TABLE [dbo].[DocumentTemplates]  WITH CHECK ADD  CONSTRAINT [EDocumentType_DocumentTemplates] FOREIGN KEY([DocumentTypeId])
REFERENCES [dbo].[DocumentTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentTemplates] CHECK CONSTRAINT [EDocumentType_DocumentTemplates]
GO
