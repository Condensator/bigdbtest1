CREATE TYPE [dbo].[FinancialStatementDocumentAttachment] AS TABLE(
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Attachment_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Content] [varbinary](82) NOT NULL,
	[UploadedDate] [date] NOT NULL,
	[UploadedById] [bigint] NOT NULL,
	[DocumentAttachmentId] [bigint] NULL,
	[FinancialStatementDocumentId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
