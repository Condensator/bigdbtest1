SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FinancialStatementDocumentAttachments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Attachment_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Content] [varbinary](82) NOT NULL,
	[UploadedDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UploadedById] [bigint] NOT NULL,
	[DocumentAttachmentId] [bigint] NULL,
	[FinancialStatementDocumentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[FinancialStatementDocumentAttachments]  WITH CHECK ADD  CONSTRAINT [EFinancialStatementDocument_FinancialStatementDocumentAttachments] FOREIGN KEY([FinancialStatementDocumentId])
REFERENCES [dbo].[FinancialStatementDocuments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FinancialStatementDocumentAttachments] CHECK CONSTRAINT [EFinancialStatementDocument_FinancialStatementDocumentAttachments]
GO
ALTER TABLE [dbo].[FinancialStatementDocumentAttachments]  WITH CHECK ADD  CONSTRAINT [EFinancialStatementDocumentAttachment_DocumentAttachment] FOREIGN KEY([DocumentAttachmentId])
REFERENCES [dbo].[DocumentAttachments] ([Id])
GO
ALTER TABLE [dbo].[FinancialStatementDocumentAttachments] CHECK CONSTRAINT [EFinancialStatementDocumentAttachment_DocumentAttachment]
GO
ALTER TABLE [dbo].[FinancialStatementDocumentAttachments]  WITH CHECK ADD  CONSTRAINT [EFinancialStatementDocumentAttachment_UploadedBy] FOREIGN KEY([UploadedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[FinancialStatementDocumentAttachments] CHECK CONSTRAINT [EFinancialStatementDocumentAttachment_UploadedBy]
GO
