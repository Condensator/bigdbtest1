SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentHeaders](
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Id] [bigint] NOT NULL,
	[LanguageId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentHeaders]  WITH CHECK ADD  CONSTRAINT [EDocumentHeader_Language] FOREIGN KEY([LanguageId])
REFERENCES [dbo].[LanguageConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentHeaders] CHECK CONSTRAINT [EDocumentHeader_Language]
GO
ALTER TABLE [dbo].[DocumentHeaders]  WITH CHECK ADD  CONSTRAINT [EEntityHeader_DocumentHeader] FOREIGN KEY([Id])
REFERENCES [dbo].[EntityHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentHeaders] CHECK CONSTRAINT [EEntityHeader_DocumentHeader]
GO
