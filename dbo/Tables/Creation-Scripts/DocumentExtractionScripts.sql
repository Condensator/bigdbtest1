SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentExtractionScripts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[SampleXML] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[MappingScript] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentExtractionScripts]  WITH CHECK ADD  CONSTRAINT [EDocumentExtractionScript_EntityType] FOREIGN KEY([EntityTypeId])
REFERENCES [dbo].[DocumentEntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentExtractionScripts] CHECK CONSTRAINT [EDocumentExtractionScript_EntityType]
GO
