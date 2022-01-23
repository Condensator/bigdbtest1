SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentInstancePhrases](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DocumentInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DocumentPhraseId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentInstancePhrases]  WITH CHECK ADD  CONSTRAINT [EDocumentInstance_DocumentInstancePhrases] FOREIGN KEY([DocumentInstanceId])
REFERENCES [dbo].[DocumentInstances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentInstancePhrases] CHECK CONSTRAINT [EDocumentInstance_DocumentInstancePhrases]
GO
ALTER TABLE [dbo].[DocumentInstancePhrases]  WITH CHECK ADD  CONSTRAINT [EDocumentInstancePhrase_DocumentPhrase] FOREIGN KEY([DocumentPhraseId])
REFERENCES [dbo].[DocumentPhrases] ([Id])
GO
ALTER TABLE [dbo].[DocumentInstancePhrases] CHECK CONSTRAINT [EDocumentInstancePhrase_DocumentPhrase]
GO
