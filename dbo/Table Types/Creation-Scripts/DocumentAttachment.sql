CREATE TYPE [dbo].[DocumentAttachment] AS TABLE(
	[RowNumber] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsModificationRequired] [bit] NOT NULL,
	[ModificationReason] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[ModificationComment] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[AttachmentId] [bigint] NOT NULL,
	[DocumentInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
