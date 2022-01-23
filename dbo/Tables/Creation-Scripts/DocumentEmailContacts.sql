SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentEmailContacts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityNaturalId] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContactName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ContactType] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Email] [nvarchar](70) COLLATE Latin1_General_CI_AS NOT NULL,
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DocumentHeaderId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentEmailContacts]  WITH CHECK ADD  CONSTRAINT [EDocumentHeader_DocumentEmailContacts] FOREIGN KEY([DocumentHeaderId])
REFERENCES [dbo].[DocumentHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentEmailContacts] CHECK CONSTRAINT [EDocumentHeader_DocumentEmailContacts]
GO
