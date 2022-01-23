CREATE TYPE [dbo].[ESignEnvelope] AS TABLE(
	[EnvelopeId] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Subject] [nvarchar](1000) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SentDate] [datetimeoffset](7) NULL,
	[CompletedDate] [datetimeoffset](7) NULL,
	[ESignSystem] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[ErrorComment] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Message] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CancellationReason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[TagViewURL] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[VaultEnabled] [bit] NOT NULL,
	[XAPIUser] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[DocumentHeaderId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
