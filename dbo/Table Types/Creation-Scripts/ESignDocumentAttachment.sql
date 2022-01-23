CREATE TYPE [dbo].[ESignDocumentAttachment] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsPacket] [bit] NOT NULL,
	[AttachmentId] [bigint] NOT NULL,
	[DocumentAttachmentId] [bigint] NULL,
	[DocumentPackAttachmentId] [bigint] NULL,
	[ESignEnvelopeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
