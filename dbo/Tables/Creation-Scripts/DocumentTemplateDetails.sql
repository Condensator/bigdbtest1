SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentTemplateDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Template_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Template_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[Template_Content] [varbinary](82) NULL,
	[ExternalTemplateKey] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LanguageId] [bigint] NOT NULL,
	[DocumentTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentTemplateDetails]  WITH CHECK ADD  CONSTRAINT [EDocumentTemplate_DocumentTemplateDetails] FOREIGN KEY([DocumentTemplateId])
REFERENCES [dbo].[DocumentTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentTemplateDetails] CHECK CONSTRAINT [EDocumentTemplate_DocumentTemplateDetails]
GO
ALTER TABLE [dbo].[DocumentTemplateDetails]  WITH CHECK ADD  CONSTRAINT [EDocumentTemplateDetail_Language] FOREIGN KEY([LanguageId])
REFERENCES [dbo].[LanguageConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentTemplateDetails] CHECK CONSTRAINT [EDocumentTemplateDetail_Language]
GO
