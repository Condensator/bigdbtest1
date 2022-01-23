SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentEmails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ToEmailId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NOT NULL,
	[CcEmailId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[BccEmailId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[FromEmailId] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[SentDate] [datetimeoffset](7) NOT NULL,
	[Status] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[StatusComment] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[RowNumber] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EmailTemplateId] [bigint] NULL,
	[SentByUserId] [bigint] NOT NULL,
	[DocumentHeaderId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentEmails]  WITH CHECK ADD  CONSTRAINT [EDocumentEmail_EmailTemplate] FOREIGN KEY([EmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[DocumentEmails] CHECK CONSTRAINT [EDocumentEmail_EmailTemplate]
GO
ALTER TABLE [dbo].[DocumentEmails]  WITH CHECK ADD  CONSTRAINT [EDocumentEmail_SentByUser] FOREIGN KEY([SentByUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[DocumentEmails] CHECK CONSTRAINT [EDocumentEmail_SentByUser]
GO
ALTER TABLE [dbo].[DocumentEmails]  WITH CHECK ADD  CONSTRAINT [EDocumentHeader_DocumentEmails] FOREIGN KEY([DocumentHeaderId])
REFERENCES [dbo].[DocumentHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentEmails] CHECK CONSTRAINT [EDocumentHeader_DocumentEmails]
GO
