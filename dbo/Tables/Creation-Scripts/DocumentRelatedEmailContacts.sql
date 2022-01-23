SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentRelatedEmailContacts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityNaturalId] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ContactName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ContactType] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Email] [nvarchar](1000) COLLATE Latin1_General_CI_AS NOT NULL,
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DocumentEmailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentRelatedEmailContacts]  WITH CHECK ADD  CONSTRAINT [EDocumentEmail_DocumentRelatedEmailContacts] FOREIGN KEY([DocumentEmailId])
REFERENCES [dbo].[DocumentEmails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentRelatedEmailContacts] CHECK CONSTRAINT [EDocumentEmail_DocumentRelatedEmailContacts]
GO
