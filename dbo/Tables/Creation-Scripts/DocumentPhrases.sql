SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentPhrases](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Phrase] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LanguageId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[EntityTypeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentPhrases]  WITH CHECK ADD  CONSTRAINT [EDocumentPhrase_EntityType] FOREIGN KEY([EntityTypeId])
REFERENCES [dbo].[DocumentEntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentPhrases] CHECK CONSTRAINT [EDocumentPhrase_EntityType]
GO
ALTER TABLE [dbo].[DocumentPhrases]  WITH CHECK ADD  CONSTRAINT [EDocumentPhrase_Language] FOREIGN KEY([LanguageId])
REFERENCES [dbo].[LanguageConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentPhrases] CHECK CONSTRAINT [EDocumentPhrase_Language]
GO
