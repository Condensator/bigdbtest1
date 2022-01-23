CREATE TYPE [dbo].[ESignEnvelopeAttachment] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CompletedAttachmentId] [bigint] NULL,
	[DocumentAttachmentId] [bigint] NULL,
	[DocumentPackAttachmentId] [bigint] NULL,
	[ESignEnvelopeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
